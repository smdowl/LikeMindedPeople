//
//  DataModel.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataModel.h"
#import <CoreLocation/CLLocationManager.h>
#import <ContextLocation/QLContentDescriptor.h>
#import <ContextLocation/QLPlaceEvent.h>
#import <ContextLocation/QLPlace.h>
#import <ContextCore/QLContextConnectorPermissions.h>
#import <ContextProfiling/PRProfile.h>
#import <ContextProfiling/PRProfileAttribute.h>
#import <ContextProfiling/PRAttributeCategory.h>
#import <ContextCore/QLContextCoreError.h>
#import "ServiceAdapter.h"

@interface DataModel()
- (void)setup;

- (void)_getPPOIList;
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

- (void)setUserId:(NSString *)userId
{
	_userId = userId;
	
//	[self runStartUpSequence];
    [self performSelector:@selector(runStartUpSequence) withObject:nil afterDelay:0.1];
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
				currentPlace = [_currentLocation objectAtIndex:0];
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
	// Update the current profile
	PRProfile *profile = self.contextInterestsConnector.interests;
//	NSLog(@"%@ %@", profile, [profile.attrs.allValues objectAtIndex:0]);
	
	NSArray *profileArray = [self _flattenProfile:profile];
	[ServiceAdapter uploadPointsOfInterest:profileArray forUser:_userId success:^(id result)
	 {
		 
	 }];
	
	// Add the new pois to the database
	[self _getPPOIList];
	[ServiceAdapter uploadPointsOfInterest:_personalPointsOfInterest forUser:_userId success:^(id result)
	 {
		 
	 }];
    
	
	
	// Get the current location to filter the results from the server
	CLLocationManager *manager = [[CLLocationManager alloc] init];
	CLLocation *location = [manager location];
	if(location) {
	[ServiceAdapter getGeofencesForUser:_userId atLocation:location success:^(NSArray *geofences)
	 {
		 [self _replacePrivateGeofencesWithFences:geofences];
	 }];
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

- (void)_getPPOIList
{
	[self.contextPlaceConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
	 {
		 _personalPointsOfInterest = ppoi;
		 
		 for (QLPlace *point in ppoi)
		 {
//			 NSLog(@"%@", point);
		 }
	 } failure:^(NSError *err)
	 {
		 
	 }];
}

- (void)test
{
	
}

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

- (void)_getPrivateFences
{
	[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
	 {
		 _privateFences = [NSMutableArray arrayWithArray:allPlaces];
//		 for (QLPlace *place in allPlaces)
//		 {
//			 NSLog(@"place id: %lli", place.id);
//			 [_privateFences addObject:place];
//		 }
	 } failure:^(NSError *err)
	 {
		 NSLog(@"%@", err);
	 }];
}

- (void)_setPrivateFences:(NSArray *)geofences
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
//		NSLog(@"%@", geofence);
	}
}

- (void)_replacePrivateGeofencesWithFences:(NSArray *)fences
{
	@synchronized(self)
	{
		[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 _privateFences = [NSMutableArray arrayWithArray:allPlaces];
			 
			 if ([_privateFences count] > 0)
			 {			 
				 _failures = 0;
				 for (QLPlace *fence in _privateFences)
				 {
					 [self _removePrivateFence:fence completion:^()
					  {
						  [self _setPrivateFences:fences];
					  }];
				 }
			 }
			 else
			 {
				 [self _setPrivateFences:fences];
			 }
			 
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
		 }];
	}
}

//- (void)_removeFence:(void (^)(void))callback
//{
//	[self.contextPlaceConnector deletePlaceWithId:geofence.id
//										  success:^(void){
//											  [_privateFences removeObject:geofence];
//											  NSLog(@"successfully removed place");
//										  } failure:^(NSError *err){
//											  NSLog(@"%@", err);
//										  }];
//}

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
