//
//  DataModel.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

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
#import "RadiiResultDTO.h"

#define REFRESH_RADIUS 1000
#define GEOFENCE_DOWNLOAD_RADIUS 3000

// TODO: work out behaiour when there is no internet. As it is now the request will just time out after about 10 seconds
// TODO: at the moment loading and unloading private locations takes a long time due to all the server interaction that is required. Try and find a faster way.

@interface DataModel()
- (void)_setup;

- (void)_uploadPersonalPointsOfInterest;
- (void)_getPrivateFencesOnCompletion:(void (^)(NSArray *))onComplete;
- (NSArray *)_flattenProfile:(PRProfile *)profile;

- (void)_replacePrivateGeofencesWithFences:(NSMutableArray *)geofenceLocations;

// Persistent storage methods
- (NSString *)_baseStoragePath;
- (NSString *)_locationsStoragePath;
- (NSString *)_userIdStoragePath;
- (void)_checkCurrentLocation;
@end

@implementation DataModel

static DataModel *_sharedInstance = nil;

@synthesize coreConnector = _coreConnector;
@synthesize placeConnector = _placeConnector;
@synthesize interestsConnector = _interestsConnector;

@synthesize locationManager = _locationManager;

@synthesize userId = _userId;

@synthesize personalPointsOfInterest = _personalPointsOfInterest;
@synthesize privateFences = _privateFences;
@synthesize geofenceRefreshLocation = _geofenceRefreshLocation;

#pragma mark -
#pragma mark Initialization Methods

+ (DataModel *)sharedInstance
{	
	@synchronized(self)
	{
		if (!_sharedInstance)
		{
			_sharedInstance = [super allocWithZone:nil];
						
			[_sharedInstance _setup];
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

- (void)_setup
{
	@synchronized(self)
	{			
		_coreConnector = [[QLContextCoreConnector alloc] init];
		_coreConnector.permissionsDelegate = _sharedInstance;
		
		_placeConnector = [[QLContextPlaceConnector alloc] init];
		_placeConnector.delegate = _sharedInstance;
		
		_interestsConnector = [[PRContextInterestsConnector alloc] init];
		_interestsConnector.delegate = _sharedInstance;
		
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.purpose = @"Let us use your location to give your personality to the places you go!";
		[_locationManager startMonitoringSignificantLocationChanges];
		
		_userId = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _userIdStoragePath]];
		
		_privateFences = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _locationsStoragePath]];
		
		if (!_privateFences)
			_privateFences = [NSMutableArray array];
		
		_currentLocation = [NSMutableArray array];
		_geofenceRefreshLocation = [[GeofenceLocation alloc] init];
	}
}

- (void)runStartUpSequence
{
	@synchronized(self)
	{
		if (_settingUp)
			return;
		
		_settingUp = YES;
		
		// TODO: Removed some empty server calls to stop traffic. Complete them
		// Update the current profile
		PRProfile *profile = _interestsConnector.interests;
		//	NSLog(@"%@ %@", profile, [profile.attrs.allValues objectAtIndex:0]);
		
		NSArray *profileArray = [self _flattenProfile:profile];
		
		//		[ServiceAdapter uploadUserProfile:profileArray forUser:_userId success:^(id result)
		//		 {
		//			 
		//		 }];
		
		// Add the new pois to the database
		//		[self _uploadPersonalPointsOfInterest];
		
		
		// Get the current location to filter the results from the server
		CLLocation *location = [_locationManager location];
		
		if (!location)
		{
			_settingUp = NO;
			return;
		}
		
		//		[self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithObject:_geofenceRefreshLocation]];
		
		//	if(location) {
		[ServiceAdapter getGeofencesForUser:_userId atLocation:location radius:GEOFENCE_DOWNLOAD_RADIUS success:^(NSArray *geofences)
		 {
			 [self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithArray:geofences]];
		 }];
		//    }
		
		//		[ServiceAdapter getGoogleSearchResultsForUser:_userId atLocation:location withName:nil withType:@"food" success:^(NSArray *results)
		//		 {
		//			 for (RadiiResultDTO *result in results)
		//			 {
		//				 NSLog(@"%@",result);
		//			 }
		//		 }];
		
		[self updateGeofenceRefreshLocation];
	}
}

// Set the ID that will be used in all server calls
- (void)setUserId:(NSString *)userId
{
	@synchronized(self)
	{
		_userId = userId;
		[NSKeyedArchiver archiveRootObject:_userId toFile:[self _userIdStoragePath]];
		[self runStartUpSequence];
	}
}

- (void)getPPOIInfo
{
	[_placeConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
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

- (NSArray *)getAllGeofenceRegions
{
	return _privateFences;
}

- (GeofenceLocation *)geofenceRefreshLocation
{
	if ([_geofenceRefreshLocation isEmpty])
	{
		[self updateGeofenceRefreshLocation];	
	}

	return _geofenceRefreshLocation;
}

- (void)updateGeofenceRefreshLocation
{
	@synchronized(self)
	{
		__weak DataModel *weakSelf = self;
		
		void (^createNewPlace)(void) = ^()
		{
			// Refresh the geofence to ensure if something doesn't work it still appears empty
			[_geofenceRefreshLocation clear];
			
			CLLocation *location = [_locationManager location];
			
			QLPlace *geofencePlace = [[QLPlace alloc] init];
			QLGeoFenceCircle *circle = [[QLGeoFenceCircle alloc] init];
			circle.latitude = location.coordinate.latitude;
			circle.longitude = location.coordinate.longitude;
			circle.radius = REFRESH_RADIUS;
			geofencePlace.name = @"Refresh boundary";
			geofencePlace.geoFence = circle;
			
			[_placeConnector createPlace:geofencePlace success:^(QLPlace *place)
			 {
				 DataModel *strongSelf = weakSelf;
				 
				 if (strongSelf)
				 {
					 strongSelf -> _geofenceRefreshLocation = [[GeofenceLocation alloc] initWithPlace:place];
				 }
			 }
								 failure:^(NSError *err)
			 {
				 NSLog(@"createPlace: %@", [err localizedDescription]);
			 }];
		};
		
		// If some already exist remove them first
		if (![_geofenceRefreshLocation isEmpty])
		{
			[_placeConnector deletePlaceWithId:_geofenceRefreshLocation.placeId 
									   success:^()
			 {
				 createNewPlace();	 
			 }
									   failure:^(NSError *err)
			 {
				 NSLog(@"deletePlace: %@", [err localizedDescription]);			 
				 createNewPlace();
			 }];
		}
		else
		{ // Otherwise just add the new ones
			createNewPlace();
		}
	}
}

- (void)addLocationListener:(id<CLLocationManagerDelegate>)listener
{
	[_locationListeners addObject:listener];
}

- (void)removeLocationListener:(id<CLLocationManagerDelegate>)listener
{
	if ([_locationListeners containsObject:listener])
		[_locationListeners removeObject:listener];
}

- (void)close
{
	_settingUp = NO;
	_placeConnector = nil;
	
	[NSKeyedArchiver archiveRootObject:_privateFences toFile:[self _locationsStoragePath]];
	[NSKeyedArchiver archiveRootObject:_userId toFile:[self _userIdStoragePath]];
}

#pragma mark -
#pragma mark Geofence listening

// TODO: Need extra thought here to ensure that the correct geofence is removed from list
- (void)didGetPlaceEvent:(QLPlaceEvent *)event
{	
	@synchronized(self)
	{
		__weak DataModel *weakSelf = self;
		// TODO: remove this
		[self _getPrivateFencesOnCompletion:^(NSArray *fences)
		 {	
			 DataModel *strongSelf = weakSelf;
			 if (!strongSelf)
				 return;
			 			 
			 GeofenceLocation *currentLocation;
			 for (GeofenceLocation *location in fences)
			 {
				 if (event.placeId == location.placeId)
				 {
					 currentLocation = location;
					 break;
				 }
			 }	
			 
			 // If the location hasn't been found then there isn't much we can do!
			 if (!currentLocation)
			 {
				 return;
			 }
			 
			 // Depending on what happened, change the current locatoin
			 switch (event.eventType)
			 {
				 case QLPlaceEventTypeAt:				
					 // Only add this place to the current location array if it isn't the flag for the geofence updates
					 if (![currentLocation isEqual:_geofenceRefreshLocation] && ![_currentLocation containsObject:currentLocation])
					 {
						 [strongSelf -> _currentLocation insertObject:currentLocation atIndex:0];
					 }
					 
					 break;
					 
				 case QLPlaceEventTypeLeft:
					 // If you just left the refresh boundary get a new one as well as all the nearby geofences
					 if ([currentLocation isEqual:_geofenceRefreshLocation])
					 {
						 [self updateGeofenceRefreshLocation];
						 
						 CLLocation *location = [_locationManager location];
						 [ServiceAdapter getGeofencesForUser:_userId atLocation:location radius:GEOFENCE_DOWNLOAD_RADIUS success:^(NSArray *geofences)
						  {
							  [self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithArray:geofences]];
						  }];
					 }
					 else
					 {
						 [strongSelf -> _currentLocation removeObjectAtIndex:0];
						 if ([strongSelf -> _currentLocation count])
						 {
							 currentLocation = [strongSelf -> _currentLocation objectAtIndex:0];
						 }
						 else
						 {
							 currentLocation = nil;
						 }
					 }
					 break;
			 }
		 }];
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

#pragma mark -
#pragma mark QLContextCorePermissionsDelegate
- (void)subscriptionPermissionDidChange:(BOOL)subscriptionPermission
{
    if (subscriptionPermission)
    {
		[self runStartUpSequence];
    }
    else
    {
		// Wipe data maybe
    }
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if (status == kCLAuthorizationStatusAuthorized)
		[self runStartUpSequence];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	for (id<CLLocationManagerDelegate> listener in _locationListeners)
		[listener locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
}

#pragma mark -
#pragma mark Private Methods

- (void)_uploadPersonalPointsOfInterest
{
	@synchronized(self)
	{
		[_placeConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
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
- (void)_getPrivateFencesOnCompletion:(void (^)(NSArray *))onComplete
{
	@synchronized(self)
	{
		[_placeConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 NSMutableArray *locations = [NSMutableArray array];
			 
			 for (QLPlace *place in allPlaces)
			 {
				 GeofenceLocation *newLocation = [[GeofenceLocation alloc] initWithPlace:place];
				 [locations addObject:newLocation];
			 }
			 
			 onComplete(locations);
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
			 onComplete(nil);
		 }];
	}
}

- (void)_replacePrivateGeofencesWithFences:(NSMutableArray *)geofenceLocations
{
	@synchronized(self)
	{
		__weak DataModel *weakSelf = self;
		// First get all places
		
		[_placeConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
		 {
			 DataModel *strongSelf = weakSelf;
			 {
			 if (!strongSelf)
				 return;
			 }
			 			 
			 // Create an array of GeofenceLocations from what is returned by the place connector
			 NSMutableArray *allLocations = [NSMutableArray array];
			 for (QLPlace *place in allPlaces)
			 {
				 GeofenceLocation *newLocation = [[GeofenceLocation alloc] initWithPlace:place];
				 [allLocations addObject:newLocation];
			 }
			 			 
			 // Remove any from our local version that are not in the new list
			 NSMutableArray *removedLocations = [NSMutableArray array];
			 for (GeofenceLocation *location in allLocations)
			 {
				 if (![geofenceLocations containsObject:location] && ![location isEqual:_geofenceRefreshLocation])
				 {
					 [removedLocations addObject:location];
				 }
				 
				 if (![_privateFences containsObject:location] && ![location isEqual:_geofenceRefreshLocation])
					 [_privateFences addObject:location];
			 }		 
			 
			 // Now work out what additional fences need to be added
			 NSMutableArray *addedFences = [NSMutableArray array];
			 for (GeofenceLocation *location in geofenceLocations)
			 {
				 if (![allLocations containsObject:location])
					 [addedFences addObject:location];
			 }
			 		 
			 // Only remove fences if there are some to remove
			 if ([removedLocations count] > 0)
			 {
				 [self _removeAllFences:removedLocations onCompletion:^()
				  {
					  NSLog(@"Finished deleting");
					  
					  __weak DataModel *weakWeakSelf = strongSelf;
					  					  
					  [strongSelf _addAllFences:addedFences onCompletion:^()
					   {
						   DataModel *strongStrongSelf = weakWeakSelf;
						   
						   if (!strongStrongSelf)
						   {
							   return;
						   }
						   strongStrongSelf->_settingUp = NO; 
						   
						   [self _checkCurrentLocation];
						   NSLog(@"Finished!");
					   }];
				  }];
			 }
			 else if (addedFences.count > 0)
			 {	 
				 __weak DataModel *weakWeakSelf = strongSelf;
				 // If there aren't any to delete it will be a simple case of just adding all the ones we need
				 [strongSelf _addAllFences:addedFences onCompletion:^()
				  {
					  NSLog(@"done");
					  DataModel *strongStrongSelf = weakWeakSelf;
					  
					  if (!strongStrongSelf)
					  {
						  return;
					  }
					  
					  strongStrongSelf->_settingUp = NO;
					  
					  [self _checkCurrentLocation];
				  }];
			 }
			 else
			 {
				 [self _checkCurrentLocation];
			 }
			 
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
			 _settingUp = NO;
		 }];
	}
}

// Go through each of the fences in the array and try to create them. Only add the next one after a successful add
// They are only added to the iVar if the addition was successful so take care with it
- (void)_addAllFences:(NSMutableArray *)geofenceLocations onCompletion:(void (^)(void))finished
{	
	if (geofenceLocations.count == 0)
	{
		finished();
		return;
	}
			
	GeofenceLocation *geofenceLocation = [geofenceLocations objectAtIndex:0];
	QLPlace *fence = [geofenceLocation place];
		
	[_placeConnector createPlace:fence
						 success:^(QLPlace *newFence)
	 {
		 [geofenceLocations removeObject:geofenceLocation];
		 
		 GeofenceLocation *newLocation = [[GeofenceLocation alloc] initWithPlace:newFence];
		 
		 if (![newLocation isEqual:_geofenceRefreshLocation])		 
			 [_privateFences addObject:newLocation];
		 
		 if (geofenceLocations.count == 0)
			 finished();
		 else
			 [self _addAllFences:geofenceLocations onCompletion:finished];
		 
	 } 
						 failure:^(NSError *err)
	 {
		 // If adding it failed then just remove it from the list to add and carry on
		 [geofenceLocations removeObject:geofenceLocation];
		 
		 if (geofenceLocations.count == 0)
		 {
			 finished();
		 }
		 else
		 {
			 [self _addAllFences:geofenceLocations onCompletion:finished];
		 }
		 
		 NSLog(@"Error: %@", err);
	 }];
}

- (void)_removeAllFences:(NSMutableArray *)geofenceLocations onCompletion:(void (^)(void))completed
{
	// Pop one fence from the stack
	GeofenceLocation *fence = [geofenceLocations objectAtIndex:0];
	
	[_placeConnector deletePlaceWithId:fence.placeId
							   success:^(void)
	 {
		 [geofenceLocations removeObject:fence];
		 [_privateFences removeObject:fence];
		 // If the stack is empty then return completed
		 if ([geofenceLocations count] == 0)
		 {
			 completed();
		 }
		 else
		 {	// Otherwise, carry on
			 [self _removeAllFences:geofenceLocations onCompletion:completed];
		 }
		 NSLog(@"successfully removed place");
	 } 
							   failure:^(NSError *err)
	 {
		 // TODO: failing a lot here. Need to cut down the number of database calls i think (persistatn storage?)
		 // Take one off the front and put it at the back to try it again
		 NSLog(@"ERROR: %@", err);
		 NSLog(@"Geofence: %lli %@", fence.placeId, fence.geofenceName);
		 [geofenceLocations removeObject:fence];
		 //											  [fences insertObject:fence atIndex:[_privateFences count]];
		 
		 // Some times we are left with
		 if ([geofenceLocations count] == 0)
		 {
			 completed();
		 }
		 else
		 {
			 [self _removeAllFences:geofenceLocations onCompletion:completed];
		 }
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
#if TARGET_IPHONE_SIMULATOR
			[categoryDictionary setValue:[NSNumber numberWithDouble:0.5] forKey:cat.key];
#endif
			[profileArray addObject:categoryDictionary];
		}
	}
	
	return profileArray;
}

- (void)_checkCurrentLocation
{
	CLLocation *location = _locationManager.location;
	for (GeofenceLocation *fence in _privateFences)
	{
		if ([fence containsPin:location.coordinate] && ![_currentLocation containsObject:fence])
		{
			[_currentLocation addObject:fence];
		}
	}
}

#pragma mark -
#pragma mark Persistent storgae filepath methods

- (NSString *)_baseStoragePath
{
	NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	return [documentsDirectories objectAtIndex:0];
}

- (NSString *)_locationsStoragePath
{
	return [[self _baseStoragePath] stringByAppendingPathComponent:@"profiles.archive"];
}
															  
- (NSString *)_userIdStoragePath
{
	return [[self _baseStoragePath] stringByAppendingPathComponent:@"userId.archive"];	
}



@end
