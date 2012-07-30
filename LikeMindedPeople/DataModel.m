//
//  DataModel.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataModel.h"
#import <CoreLocation/CoreLocation.h>
#import <ContextLocation/QLContentDescriptor.h>
#import <ContextLocation/QLPlaceEvent.h>
#import <ContextLocation/QLPlace.h>
#import <ContextCore/QLContextConnectorPermissions.h>
#import <ContextProfiling/PRProfile.h>
#import <ContextProfiling/PRProfileAttribute.h>
#import <ContextProfiling/PRAttributeCategory.h>
#import <ContextCore/QLContextCoreError.h>
#import "ServiceAdapter.h"
#import "GeofenceLocation.h"

@interface DataModel()
- (void)setup;

- (void)_uploadPersonalPointsOfInterest;
- (void)_replacePrivateGeofencesWithFences:(NSArray *)fences; // Remove
- (void)_getPrivateFences;
- (NSArray *)_flattenProfile:(PRProfile *)profile;
- (void)_setPrivateFences:(NSArray *)geofences;
- (void)_removePrivateFence:(QLPlace *)fence completion:(void (^)(void ))complete;
@end

@implementation DataModel

static DataModel *_sharedInstance = nil;

@synthesize contextCoreConnector;
@synthesize contextPlaceConnector;
@synthesize contextInterestsConnector;

@synthesize userId = _userId;

@synthesize placeEvents = _placeEvents;
@synthesize personalPointsOfInterest = _personalPointsOfInterest;
@synthesize privateFences = _privateFences;

#pragma mark -
#pragma mark Initialization Methods

+ (DataModel *)sharedInstance
{	
	@synchronized(self)
	{
		if (!_sharedInstance)
		{
			_sharedInstance = [super allocWithZone:nil];
			
			_sharedInstance.contextCoreConnector = [[QLContextCoreConnector alloc] init];
			_sharedInstance.contextCoreConnector.permissionsDelegate = _sharedInstance;
			
			_sharedInstance.contextPlaceConnector = [[QLContextPlaceConnector alloc] init];
			_sharedInstance.contextPlaceConnector.delegate = _sharedInstance;
			
			_sharedInstance.contextInterestsConnector = [[PRContextInterestsConnector alloc] init];
			_sharedInstance.contextInterestsConnector.delegate = _sharedInstance;
			
			[_sharedInstance setup];
		}
		
		return _sharedInstance;
	}
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [DataModel sharedInstance];
}

- (id)init
{
	return [DataModel sharedInstance];
}

#pragma mark -
#pragma mark Setup Methods

- (void)setup
{
	@synchronized(self)
	{
		_privateFences = nil;
		_currentLocation = [NSMutableArray array];
		
		[self.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *contextConnectorPermissions) 
		 {
			 
			 // Get all the events that the user has recently been sent
			 [self.contextPlaceConnector requestLatestPlaceEventsAndOnSuccess:^(NSArray *placeEvents) 
			  {
				  
				  _placeEvents = placeEvents;
				  
			  } failure:^(NSError *error) {
				  NSLog(@"%@", [error localizedDescription]);
			  }];
		 }	disabled:^(NSError *error) {
			 NSLog(@"%@", error);
			 if (error.code == QLContextCoreNonCompatibleOSVersion)
			 {
				 NSLog(@"%@", @"SDK Requires iOS 5.0 or higher");
			 }
			 else 
			 {
				 // Authentication, going to happen from 
				 //          enableSDKButton.enabled = YES;
			 }
		 }];
	}
}

- (void)setUserId:(NSString *)userId
{
	@synchronized(self)
	{
		_userId = userId;
		
		[self performSelector:@selector(runStartUpSequence) withObject:nil afterDelay:0.1];
	}
}

- (void)getInfo
{
	[self.contextPlaceConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
	 {
		 for (QLPlaceEvent *event in ppoi)
		 {
//			 NSLog(@"%@", event);
		 }
	 } failure:^(NSError *err)
	 {
		 
	 }];
}

#pragma mark -
#pragma mark External Methods

- (QLPlace *)currentLocation
{
	if ([_currentLocation count] > 0)
		return [_currentLocation objectAtIndex:0];
	else
		return nil;
}

- (GeofenceLocation *)getInfoForPin:(CLLocationCoordinate2D)pin
{
	// Try to find the description that matches
	for (GeofenceLocation *location in _geofenceSearchLocations)
	{
		if ([location containsPin:pin])
			return location;
	}
	
	// Otherwise return nil which is interpreted as zero
	
	return nil;
}

#pragma mark -
#pragma mark Internal Methods

#pragma mark -
#pragma mark Geofence listening

- (void)didGetPlaceEvent:(QLPlaceEvent *)event
{	
	@synchronized(self)
	{
		QLPlace *currentPlace;

		[self _getPrivateFences];
		while (!_privateFences) {};
		
		NSLog(@"event name: %@", event.placeName);
		
		// Depending on what happened, change the current locatoin
		switch (event.eventType)
		{
			case QLPlaceEventTypeAt:
				NSLog(@"event id: %li", event.placeId);
				
				// Find this place in the full list
				for (QLPlace *place in _privateFences)
				{
					NSLog(@"Stored place id: %lli", place.id);
					if (event.placeId == place.id)
					{
						currentPlace = place;
						break;
					}
				}
				if (currentPlace)
				{
					[_currentLocation insertObject:currentPlace atIndex:0];
				}
				
				break;
				
			case QLPlaceEventTypeLeft:
				[_currentLocation removeObjectAtIndex:0];
				if ([_currentLocation count])
				{
					currentPlace = [_currentLocation objectAtIndex:0];
				}
				else
				{
					currentPlace = nil;
				}
				break;
		}
	}
	// TODO: Server, set current location
}


#pragma mark - QLContextCorePermissionsDelegate methods

- (void)interestsDidChange:(PRProfile *)interests
{
	NSLog(@"User profile did change: %@", [interests description]);
}

- (void)interestsPermissionDidChange:(BOOL)interestsPermission
{
    NSLog(@"Interests permission did change to: %d", interestsPermission);
}

- (void)runStartUpSequence
{
	@synchronized(self)
	{
		// Update the current profile
		PRProfile *profile = self.contextInterestsConnector.interests;
		//	NSLog(@"%@ %@", profile, [profile.attrs.allValues objectAtIndex:0]);
		
		NSArray *profileArray = [self _flattenProfile:profile];
		[ServiceAdapter uploadUserProfile:profileArray forUser:_userId success:^(id result)
		 {
			 
		 }];
		
		// Add the new pois to the database
		[self _uploadPersonalPointsOfInterest];
		
		
		// Get the current location to filter the results from the server
		CLLocationManager *manager = [[CLLocationManager alloc] init];
		CLLocation *location = [manager location];
		//	if(location) {
		[ServiceAdapter getGeofencesForUser:_userId atLocation:location success:^(NSArray *geofences)
		 {
			 _geofenceSearchLocations = geofences;
			 NSMutableArray *places = [NSMutableArray array];
			 for (GeofenceLocation *geofence in geofences)
			 {
				 NSLog(@"%@", geofence.place.name);
				 [places addObject:geofence.place];
			 }
			 
			 [self _replacePrivateGeofencesWithFences:places];
		 }];
		//    }
	}
}

#pragma mark -
#pragma mark QLContextCorePermissionsDelegate
- (void)subscriptionPermissionDidChange:(BOOL)subscriptionPermission
{
    if (subscriptionPermission)
    {
		[self setup];
    }
    else
    {
		// Wipe data maybe
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)_uploadPersonalPointsOfInterest
{
	@synchronized(self)
	{
		[self.contextPlaceConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
		 {
			 _personalPointsOfInterest = ppoi;
			 
			 [ServiceAdapter uploadPointsOfInterest:_personalPointsOfInterest 
											forUser:_userId 
											success:^(id result)
			  {
				  // Do something useful with result
			  }];
		 } failure:^(NSError *err)
		 {
			 
		 }];
	}
}

// This method removes a single fences and then calls the completion block if it was the last in the array
// This is one way of handling the asyn calls, probably better ways
- (void)_removePrivateFence:(QLPlace *)geofence completion:(void (^)(void ))complete
{
	NSLog(@"Geofence: %lli %@: %@", geofence.id, geofence.name, geofence.geoFence);
		
	[self.contextPlaceConnector deletePlaceWithId:geofence.id
										  success:^(void){
											  [_privateFences removeObject:geofence];
											  
											  if ([_privateFences count] == _failures)
											  {
												  complete();
											  }
											  NSLog(@"successfully removed place");
										  } failure:^(NSError *err){
											  NSLog(@"ERROR: %@", err);
											  _failures++;
											  
											  if ([_privateFences count] == _failures)
											  {
												  complete();
											  }
										  }];
}

// Access the local store and create a copy of all the private fences
- (void)_getPrivateFences
{
	@synchronized(self)
	{
		[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 _privateFences = [NSMutableArray arrayWithArray:allPlaces];
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
		 }];
	}
}

// Go through each of the fences in the array and try to create them
// They are only added to the iVar if the addition was successful so take care with it
- (void)_setPrivateFences:(NSArray *)geofences
{
	@synchronized(self)
	{
		if (_privateFences == nil)
		{
			_privateFences = [NSMutableArray array];
		}
		
		for (QLPlace *geofence in geofences)
		{
			[self.contextPlaceConnector createPlace:geofence 
											success:^(QLPlace *newFence)
			 {
				 [_privateFences addObject:geofence];
			 } failure:^(NSError *err){
				 NSLog(@"%@", err);
			 }];
		}
	}
}

- (void)_replacePrivateGeofencesWithFences:(NSArray *)fences
{
	@synchronized(self)
	{
		// First get all places
		[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 _privateFences = [NSMutableArray arrayWithArray:allPlaces];
			 
			 // Only remove fences if there are some!
			 if ([_privateFences count] > 0)
			 {			 
				 // The failures iVar keeps track of how many removes didn't work
				 // We need this because without it we don't know when to call the completion block
				 _failures = 0;
				 for (QLPlace *fence in _privateFences)
				 {
					 // Pass the same completion block to each method call, it should only be called once.
					 [self _removePrivateFence:fence completion:^()
					  {
						  [self _setPrivateFences:fences];
					  }];
				 }
			 }
			 else
			 {	 // If there aren't any to delete it will be a simple case of just adding all the ones we need
				 [self _setPrivateFences:fences];
			 }
			 
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
		 }];
	}
}

// A convenience method for making a PRProfile more manageable for JSON
- (NSArray *)_flattenProfile:(PRProfile *)profile
{
	NSMutableArray *profileArray = [NSMutableArray array];
	for (NSString *key in [profile.attrs allKeys])
	{
		PRProfileAttribute *attr = [profile getAttribute:key];
		
		for (PRAttributeCategory *cat in attr.attributeCategories)
		{
			NSDictionary *categoryDictionary = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithDouble:cat.likelihood] forKey:cat.key];
			[profileArray addObject:categoryDictionary];
		}
	}
	
	return profileArray;
}

@end
