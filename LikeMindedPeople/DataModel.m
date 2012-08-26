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

#define GEOFENCE_DOWNLOAD_RADIUS 0.5

#define REFRESH_BOUNDARY_KEY @"Refresh Boundary"

// TODO: work out behaiour when there is no internet. As it is now the request will just time out after about 10 seconds
// TODO: at the moment loading and unloading private locations takes a long time due to all the server interaction that is required. Try and find a faster way.

@interface DataModel()
- (void)_setup;

- (void)_uploadPersonalPointsOfInterest;
- (void)_getPrivateFencesOnCompletion:(void (^)(NSArray *))onComplete;
- (NSArray *)_flattenProfile:(PRProfile *)profile;

- (void)_replacePrivateGeofencesWithFences:(NSMutableArray *)geofenceLocations;

- (void)_checkCurrentLocation;

- (void)_refreshPrivateFences;	// Calls the gimbal sdk and replaces the private fences with that list

// Persistent storage methods
- (NSString *)_baseStoragePath;
- (NSString *)_locationsStoragePath;
- (NSString *)_userIdStoragePath;
- (NSString *)_geofenceRefreshLocationStoragePath;
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
		_locationManager.purpose = @"Providing your location will allow you to influence the personality of the places you go";
		[_locationManager startMonitoringSignificantLocationChanges];
		
		_userId = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _userIdStoragePath]];
		
		_privateFences = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _locationsStoragePath]];
		if (!_privateFences)
			_privateFences = [NSMutableArray array];
		
		_geofenceRefreshLocation = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _geofenceRefreshLocationStoragePath]];
		if  (!_geofenceRefreshLocation)
			_geofenceRefreshLocation = [[GeofenceLocation alloc] init];
		
		_currentLocations = [NSMutableArray array];
	}
}

- (void)runStartUpSequence
{
	@synchronized(self)
	{
		if (_settingUp)
			return;
		else
			_settingUp = YES;
		
		// There will be no place connector if the app is just starting up because the last one will of been released
		if (!_placeConnector)
		{
			_placeConnector = [[QLContextPlaceConnector alloc] init];
			_placeConnector.delegate = _sharedInstance;
		}
		
		if (!_userId)
			return;
		
		// Update the current profile
		PRProfile *profile = _interestsConnector.interests;
		
		NSArray *profileArray = [self _flattenProfile:profile];
		
		[ServiceAdapter uploadUserProfile:profileArray forUser:_userId success:^(id result)
		 {
			 
		 }
								  failure:^(NSError *error)
		 {

		 }];
		
		// Add the new pois to the database
		//		[self _uploadPersonalPointsOfInterest];
		
		
		// Get the current location to filter the results from the server
		CLLocation *location = [_locationManager location];
		
		if (!location)
		{
			_settingUp = NO;
			return;
		}
				
		[ServiceAdapter getGeofencesForUser:_userId atLocation:location radius:GEOFENCE_DOWNLOAD_RADIUS success:^(NSArray *geofences)
		 {
//			 for (GeofenceLocation *geofence in geofences)
//			 {
//				 // Testing the enter/exit fence
//				 [ServiceAdapter enterGeofence:geofence userId:_userId success:^(id success)
//				  {
//					  NSLog(@"success enter: %@", success);
//					  [ServiceAdapter exitGeofence:geofence userId:_userId success:^(id success)
//					   {
//						   NSLog(@"success exit: %@", success);
//					   }];
//				  }];
//				 
//			 }
			 if (!_updatingPlaces)
				 [self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithArray:geofences]];
		 }
									failure:^(NSError *error)
		 {
			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:NSStringFromSelector(_cmd) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			 [alertView show];
		 }];
		
				
		// Check to see if the refresh location hasn't been set up yet and whether the user is now outside of it
		if ([_geofenceRefreshLocation isEmpty])
			[self updateGeofenceRefreshLocation];
		else if (![_geofenceRefreshLocation containsCoordinate:location.coordinate])
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

- (NSArray *)currentLocations
{
	return _currentLocations;
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
			circle.radius = GEOFENCE_DOWNLOAD_RADIUS / 2 * 1000;
			geofencePlace.name = REFRESH_BOUNDARY_KEY;
			geofencePlace.geoFence = circle;
			
			GeofenceLocation *newRefreshLocation = [[GeofenceLocation alloc] initWithPlace:geofencePlace];
						
			[self _addAllFences:[NSMutableArray arrayWithObject:newRefreshLocation] onCompletion:^(void)
			 {
				 if (!weakSelf)
					 return;
				 
				 DataModel *strongSelf = weakSelf;
					 
				 // TODO: Want to handle the situation where the data model is already updating
//				 if (strongSelf->_updatingPlaces)
//				 {
//					 strongSelf->_cancelUpdate = YES;
//				 }
//				 
//				 while (strongSelf->_cancelUpdate)
//				 {
//					 [NSThread sleepForTimeInterval:1];
//				 }
				 
				 strongSelf -> _updatingPlaces = YES;
				 
				 CLLocation *location = [strongSelf->_locationManager location];
				 [ServiceAdapter getGeofencesForUser:strongSelf->_userId atLocation:location radius:GEOFENCE_DOWNLOAD_RADIUS success:^(NSArray *geofences)
				  {
					  [strongSelf _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithArray:geofences]];
				  }
											 failure:^(NSError *error)
				  {
					  			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:NSStringFromSelector(_cmd) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					  [alertView show];
				  }];
			 }];
		};
		
		// Get the most recent geofence refresh location
		[self.placeConnector allPlacesAndOnSuccess:^(NSArray *places)
		 {
			for (QLPlace *place in places)
			{
				if ([place.name isEqualToString:REFRESH_BOUNDARY_KEY])
					_geofenceRefreshLocation = [[GeofenceLocation alloc] initWithPlace:place];
			}
			 
			 if ([_geofenceRefreshLocation containsCoordinate:[[_locationManager location] coordinate]])
				 return;
			 
			 // If some already exist remove them first
			 if (![_geofenceRefreshLocation isEmpty])
			 {
				 [self _removeAllFences:[NSMutableArray arrayWithObject:_geofenceRefreshLocation]
											onCompletion:createNewPlace];

			 }
			 else
			 { 
				 
				 createNewPlace();
			 }
		 }
										   failure:^(NSError *err)
		 {
			 NSLog(@"%@", [err localizedDescription]);
		 }];
		
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
	_cancelUpdate = YES;
	_updatingPlaces = NO; 
	
	[NSKeyedArchiver archiveRootObject:_privateFences toFile:[self _locationsStoragePath]];
	[NSKeyedArchiver archiveRootObject:_userId toFile:[self _userIdStoragePath]];
	[NSKeyedArchiver archiveRootObject:_geofenceRefreshLocation toFile:[self _geofenceRefreshLocationStoragePath]];
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

			 NSError *err;
			 NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@" <[^;]*>" options:NSRegularExpressionCaseInsensitive error:&err];
			 currentLocation.geofenceName = [regularExpression stringByReplacingMatchesInString:currentLocation.geofenceName options:NSMatchingReportProgress range:NSMakeRange(0, currentLocation.geofenceName.length) withTemplate:@""];
			 
			 // Depending on what happened, change the current locatoin
			 switch (event.eventType)
			 {
				 case QLPlaceEventTypeAt:				
					 // Only add this place to the current location array if it isn't the flag for the geofence updates
					 if (![currentLocation isEqual:_geofenceRefreshLocation] && ![_currentLocations containsObject:currentLocation])
					 {
						 [ServiceAdapter enterGeofence:currentLocation userId:_userId success:^(id success)
						  {
							  if (![strongSelf->_currentLocations containsObject:currentLocation])
								  [strongSelf -> _currentLocations insertObject:currentLocation atIndex:0];
						  }
											   failure:^(NSError *error)
						  {
							  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
							  [alertView show];
						  }];
					 }
					 
					 break;
					 
				 case QLPlaceEventTypeLeft:
					 // If you just left the refresh boundary get a new one as well as all the nearby geofences
					 if ([currentLocation.geofenceName isEqualToString:REFRESH_BOUNDARY_KEY])
					 {
						 [self updateGeofenceRefreshLocation];
					 }
					 else
					 {
						 if ([strongSelf -> _currentLocations containsObject:currentLocation])
						 {
							 [ServiceAdapter exitGeofence:currentLocation userId:_userId success:^(id result)
							  {
								  [strongSelf -> _currentLocations removeObject:currentLocation];
							  }
												  failure:^(NSError *error)
							  {
								  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
								  [alertView show];
							  }];
						 }
						 
						 if ([strongSelf -> _currentLocations count])
						 {
							 currentLocation = [strongSelf -> _currentLocations objectAtIndex:0];
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
			  }
											failure:^(NSError *error)
			  {
			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:NSStringFromSelector(_cmd) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				  [alertView show];
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
		 } 
									   failure:^(NSError *err)
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
			
			 if (!strongSelf)
				 return;
			 
			 if (_cancelUpdate)
			 {
				 _settingUp = NO;
				 _cancelUpdate = NO;
				 return;
			 }
			 
			 _updatingPlaces = YES;
			 			 
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
				 if (![geofenceLocations containsObject:location] && ![location.geofenceName isEqual:REFRESH_BOUNDARY_KEY])
				 {
					 [removedLocations addObject:location];
				 }
				 
//				 if ([_privateFences containsObject:location])
//					 [_privateFences removeObject:location];
			 }		 
			 
			 // Now work out what additional fences need to be added
			 NSMutableArray *addedFences = [NSMutableArray array];
			 for (GeofenceLocation *location in geofenceLocations)
			 {
				 if (![allLocations containsObject:location])
					 [addedFences addObject:location];
				 
				 if (![_privateFences containsObject:location] && ![location.geofenceName isEqual:REFRESH_BOUNDARY_KEY])
					 [_privateFences addObject:location];
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
						   strongStrongSelf->_updatingPlaces = NO; 
						   if (strongStrongSelf->_cancelUpdate) 
						   {
							   strongStrongSelf->_cancelUpdate = NO; 
							   return;
						   }
						   
						   [strongStrongSelf _checkCurrentLocation];
						   [strongStrongSelf _refreshPrivateFences];
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
					  strongStrongSelf->_updatingPlaces = NO; 
					  if (strongStrongSelf->_cancelUpdate) 
					  {
						  strongStrongSelf->_cancelUpdate = NO; 
						  return;
					  }
					  
					  [strongStrongSelf _checkCurrentLocation];
					  [strongStrongSelf _refreshPrivateFences];
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
			 _updatingPlaces = NO; 
			 _cancelUpdate = NO;
		 }];
	}
}

// Go through each of the fences in the array and try to create them. Only add the next one after a successful add
// They are only added to the iVar if the addition was successful so take care with it
- (void)_addAllFences:(NSMutableArray *)geofenceLocations onCompletion:(void (^)(void))finished
{	
	@synchronized(self)
	{
		if (geofenceLocations.count == 0 || _cancelUpdate)
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
			 			 
			 if (![newFence.name isEqualToString:REFRESH_BOUNDARY_KEY])		 
			 {			 
				 GeofenceLocation *newLocation = [[GeofenceLocation alloc] initWithPlace:newFence];
				 if (![_privateFences containsObject:newLocation])
					 [_privateFences addObject:newLocation];
			 }
			 else
			 {
				 _geofenceRefreshLocation = [[GeofenceLocation alloc] initWithPlace:newFence];
			 }
			 
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
}

- (void)_removeAllFences:(NSMutableArray *)geofenceLocations onCompletion:(void (^)(void))completed
{
	@synchronized(self)
	{
		if (geofenceLocations.count == 0 || _cancelUpdate)
		{
			completed();
			return;
		}
		
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
			 [_privateFences removeObject:fence];
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
	NSMutableArray *locationsToRemove = [NSMutableArray array];
	for (GeofenceLocation *location in _currentLocations)
	{
		if (![_privateFences containsObject:location])
			[locationsToRemove addObject:location];
	}
	[_currentLocations removeObjectsInArray:locationsToRemove];	
	
	CLLocation *location = _locationManager.location;
	for (GeofenceLocation *fence in _privateFences)
	{
		if ([fence containsCoordinate:location.coordinate] && ![_currentLocations containsObject:fence])
		{
			[_currentLocations addObject:fence];
		}
	}
}

- (void)_refreshPrivateFences
{
	[_placeConnector allPlacesAndOnSuccess:^(NSArray *places)
	 {
		 _privateFences = [NSMutableArray array];
		 for (QLPlace *place in places)
		 {
			 [_privateFences addObject:[[GeofenceLocation alloc] initWithPlace:place]];
		 }
	 }
	 failure:^(NSError *err)
	 {
		 NSLog(@"%@", [err localizedDescription]);
	 }];
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

- (NSString *)_geofenceRefreshLocationStoragePath
{
	return [[self _baseStoragePath] stringByAppendingPathComponent:@"geofenceRefreshLocation.archive"];	
}


@end
