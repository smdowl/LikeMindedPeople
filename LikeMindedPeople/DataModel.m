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
#import <ContextLocation/QLGeofenceCircle.h>
#import <ContextCore/QLContextConnectorPermissions.h>
#import <ContextProfiling/PRProfile.h>
#import <ContextProfiling/PRProfileAttribute.h>
#import <ContextProfiling/PRAttributeCategory.h>
#import <ContextCore/QLContextCoreError.h>
#import "ServiceAdapter.h"
#import "GeofenceLocation.h"

// TODO: work out behaiour when there is no internet. As it is now the request will just time out after about 10 seconds
// TODO: at the moment loading and unloading private locations takes a long time due to all the server interaction that is required. Try and find a faster way.

@interface DataModel()
- (void)setup;

- (void)_uploadPersonalPointsOfInterest;
- (void)_replacePrivateGeofencesWithFences:(NSArray *)fences; // Remove
- (void)_getPrivateFences;
- (NSArray *)_flattenProfile:(PRProfile *)profile;
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
		// This is where we should load all variables from the persistent storage
//		_privateFences = [NSKeyedUnarchiver unarchiveObjectWithFile:<#(NSString *)#>;
		_privateFences = nil;
		_currentLocation = [NSMutableArray array];
		
		[self _getPrivateFences];
		
		[self.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *contextConnectorPermissions) 
		 {
			 
//			 // Get all the events that the user has recently been sent - NOT SURE IF WE NEED THIS
//			 [self.contextPlaceConnector requestLatestPlaceEventsAndOnSuccess:^(NSArray *placeEvents) 
//			  {
//				  _placeEvents = placeEvents;
//				  
//			  } failure:^(NSError *error) {
//				  NSLog(@"%@", [error localizedDescription]);
//			  }];
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

// Set the ID that will be used in all server calls
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

- (NSArray *)getAllGeofenceRegions
{
	// Unused code
	NSMutableArray *regions = [NSMutableArray array];
	
	for (QLPlace *geofence in _privateFences)
	{
		QLGeoFenceCircle *circle = (QLGeoFenceCircle *)geofence.geoFence;
		
		CLLocationCoordinate2D center;
		center.latitude = circle.latitude;
		center.longitude = circle.longitude;
		
		CLRegion *geofenceRegion = [[CLRegion alloc] initCircularRegionWithCenter:center radius:circle.radius identifier:@"geoRegion"];
		[regions addObject:geofenceRegion];
	}
	
	return _geofenceSearchLocations;
}

#pragma mark -
#pragma mark Geofence listening

- (void)didGetPlaceEvent:(QLPlaceEvent *)event
{	
	@synchronized(self)
	{
		QLPlace *currentPlace;

		// TODO: remove this
		[self _getPrivateFences];
		while (!_privateFences) {};
		
		NSLog(@"event name: %@", event.placeName);
		
		// Depending on what happened, change the current locatoin
		switch (event.eventType)
		{
			case QLPlaceEventTypeAt:				
				// Find this place in the full list
				for (QLPlace *place in _privateFences)
				{
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
		if (_settingUp)
		{
			return;
		}
		
		_settingUp = YES;
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

- (void)_replacePrivateGeofencesWithFences:(NSMutableArray *)fences
{
	@synchronized(self)
	{
		__weak DataModel *weakSelf = self;
		// First get all places
		[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 if (!weakSelf)
			 {
				 return;
			 }
			 
			 weakSelf->_privateFences = [NSMutableArray arrayWithArray:allPlaces];
			 
			 // Only remove fences if there are some!
			 if ([weakSelf->_privateFences count] > 0)
			 {			 				 
				 [self _removeAllFences:weakSelf->_privateFences onCompletion:^()
				  {
					  NSLog(@"Finished!");
					  [self _addAllFences:fences onCompletion:^()
					   {
						   if (!weakSelf)
						   {
							   return;
						   }
						   weakSelf->_settingUp = NO; 
						   NSLog(@"Finished!");
					   }];
				  }];
			 }
			 else
			 {	 // If there aren't any to delete it will be a simple case of just adding all the ones we need
//				 [self _setPrivateFences:fences];
				 [self _addAllFences:fences onCompletion:^()
				 {
					 NSLog(@"done");
				 }];
				 weakSelf->_settingUp = NO;
			 }
			 
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
		 }];
	}
}

// Go through each of the fences in the array and try to create them. Only add the next one after a successful add
// They are only added to the iVar if the addition was successful so take care with it
- (void)_addAllFences:(NSMutableArray *)fences onCompletion:(void (^)(void))finished
{
	if (_privateFences == nil)
	{
		_privateFences = [NSMutableArray array];
	}
	
	QLPlace *fence = [fences objectAtIndex:0];
	[self.contextPlaceConnector createPlace:fence
									success:^(QLPlace *newFence)
	 {
		 [fences removeObject:fence];
		 [_privateFences addObject:fence];
		 
		 if (fences.count == 0)
		 {
			 finished();
		 }
		 else
		 {
			 [self _addAllFences:fences onCompletion:finished];
		 }
	 } 
									failure:^(NSError *err)
	 {
		 NSLog(@"Error: %@", err);
	 }];
}

- (void)_removeAllFences:(NSMutableArray *)fences onCompletion:(void (^)(void))completed
{
	// Pop one fence from the stack
	QLPlace *fence = [fences objectAtIndex:0];
		
	[self.contextPlaceConnector deletePlaceWithId:fence.id
										  success:^(void){
											  [fences removeObject:fence];
											  
											  if ([fences count] == 0)
											  {
												  completed();
											  }
											  else
											  {
												  [self _removeAllFences:fences onCompletion:completed];
											  }
											  NSLog(@"successfully removed place");
										  } failure:^(NSError *err){
											  // TODO: failing a lot here. Need to cut down the number of database calls i think (persistatn storage?)
											  // Take one off the front and put it at the back to try it again
											  NSLog(@"ERROR: %@", err);
											  NSLog(@"Geofence: %lli %@: %@", fence.id, fence.name, fence.geoFence);
											  [fences removeObject:fence];
											  [fences insertObject:fence atIndex:[_privateFences count]-1];
											  
											  [self _removeAllFences:fences onCompletion:completed];
										  }];
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

- (void)close
{
	_settingUp = NO;
}

@end
