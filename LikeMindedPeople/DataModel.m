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
- (void)_getPrivateFencesOnCompletion:(void (^)(NSArray *))onComplete;
- (NSArray *)_flattenProfile:(PRProfile *)profile;

- (void)_replacePrivateGeofencesWithFences:(NSMutableArray *)geofenceLocations;
- (void)_updateGeofenceRefreshLocation;

// Persistent storage methods
- (NSString *)_locationsStoragePath;

@end

@implementation DataModel

static DataModel *_sharedInstance = nil;

@synthesize coreConnector = _coreConnector;
@synthesize placeConnector = _placeConnector;
@synthesize interestsConnector = _interestsConnector;

@synthesize userId = _userId;

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
			
			_sharedInstance.coreConnector = [[QLContextCoreConnector alloc] init];
			_sharedInstance.coreConnector.permissionsDelegate = _sharedInstance;
			
			_sharedInstance.placeConnector = [[QLContextPlaceConnector alloc] init];
			_sharedInstance.placeConnector.delegate = _sharedInstance;
			
			_sharedInstance.interestsConnector = [[PRContextInterestsConnector alloc] init];
			_sharedInstance.interestsConnector.delegate = _sharedInstance;
			
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
		_privateFences = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _locationsStoragePath]];
		_currentLocation = [NSMutableArray array];
		
		[_coreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *contextConnectorPermissions) 
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

- (GeofenceLocation *)getInfoForPin:(CLLocationCoordinate2D)pin
{
	// Try to find the description that matches
	for (GeofenceLocation *location in _privateFences)
	{
		if ([location containsPin:pin])
			return location;
	}
	
	// Otherwise return nil which is interpreted as zero
	
	return nil;
}

- (NSArray *)getAllGeofenceRegions
{
	return _privateFences;
}

- (void)close
{
	_settingUp = NO;
	_placeConnector = nil;
	
	[NSKeyedArchiver archiveRootObject:_privateFences toFile:[self _locationsStoragePath]];
	
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
					 if (![currentLocation isEqual:_geofenceRefreshLocation])
					 {
						 [strongSelf -> _currentLocation insertObject:currentLocation atIndex:0];
					 }
					 
					 break;
					 
				 case QLPlaceEventTypeLeft:
					 if ([currentLocation isEqual:_geofenceRefreshLocation])
					 {
						 NSLog(@"Create new Geofence for refresh and break");
						 [self _updateGeofenceRefreshLocation];
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

- (void)runStartUpSequence
{
	@synchronized(self)
	{
		if (_settingUp)
		{
			return;
		}
		
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
		CLLocationManager *manager = [[CLLocationManager alloc] init];
		CLLocation *location = [manager location];
		
		// TODO: decide if this actually does anything. Need to stop the location being updated constantly
		[manager stopUpdatingLocation];
		[manager stopUpdatingHeading];
		manager = nil;
		
		// Create a place around the current location to be used to trigger the refresh
		QLPlace *geofencePlace = [[QLPlace alloc] init];
		QLGeoFenceCircle *circle = [[QLGeoFenceCircle alloc] init];
		circle.latitude = location.coordinate.latitude;
		circle.longitude = location.coordinate.longitude;
		circle.radius = 1000;
		geofencePlace.name = @"Refresh boundary";
		geofencePlace.geoFence = circle;
		
		_geofenceRefreshLocation = [[GeofenceLocation alloc] initWithPlace:geofencePlace];
		
		[self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithObject:_geofenceRefreshLocation]];
		
		//	if(location) {
//		[ServiceAdapter getGeofencesForUser:_userId atLocation:location success:^(NSArray *geofences)
//		 {
//			 [self _replacePrivateGeofencesWithFences:[NSMutableArray arrayWithArray:geofences]];
//		 }];
		//    }
		
		[ServiceAdapter getGoogleSearchResultsForUser:_userId atLocation:location withName:nil withType:@"food" success:^(NSArray *results)
		 {
			 for (NSObject *obj in results)
			 {
				 NSDictionary *result = (NSDictionary *)obj;
				 NSLog(@"%@",result);
			 }
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
//			 _privateFences = [NSMutableArray array];
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
			 {
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
			 }		 
			 
			 // Only remove fences if there are some to remove
			 if ([removedLocations count] > 0)
			 {
				 [self _removeAllFences:removedLocations onCompletion:^()
				  {
					  NSLog(@"Finished deleting");
					  
					  __weak DataModel *weakWeakSelf = strongSelf;
					  
					  // Now work out what additional fences need to be added
					  NSMutableArray *addedFences = [NSMutableArray array];
					  for (GeofenceLocation *location in geofenceLocations)
					  {
						  if (![strongSelf->_privateFences containsObject:location])
						  {
							  [addedFences addObject:location];
						  }
					  }
					  
					  [strongSelf _addAllFences:addedFences onCompletion:^()
					   {
						   DataModel *strongStrongSelf = weakWeakSelf;
						   
						   if (!strongStrongSelf)
						   {
							   return;
						   }
						   strongStrongSelf->_settingUp = NO; 
						   NSLog(@"Finished!");
					   }];
				  }];
			 }
			 else
			 {	 
				 __weak DataModel *weakWeakSelf = strongSelf;
				 // If there aren't any to delete it will be a simple case of just adding all the ones we need
				 [strongSelf _addAllFences:geofenceLocations onCompletion:^()
				  {
					  NSLog(@"done");
					  DataModel *strongStrongSelf = weakWeakSelf;
					  
					  if (!strongStrongSelf)
					  {
						  return;
					  }
					  
					  strongStrongSelf->_settingUp = NO;
				  }];
			 }
			 
		 } failure:^(NSError *err)
		 {
			 NSLog(@"%@", err);
		 }];
	}
}

- (void)_updateGeofenceRefreshLocation
{
	@synchronized(self)
	{
		// Dot the switch
	}
}

// Go through each of the fences in the array and try to create them. Only add the next one after a successful add
// They are only added to the iVar if the addition was successful so take care with it
- (void)_addAllFences:(NSMutableArray *)geofenceLocations onCompletion:(void (^)(void))finished
{
//	if (_privateFences == nil)
//	{
		_privateFences = [NSMutableArray array];
//	}
	
	GeofenceLocation *geofenceLocation = [geofenceLocations objectAtIndex:0];
	QLPlace *fence = [geofenceLocation place];
	
	[_placeConnector createPlace:fence
						 success:^(QLPlace *newFence)
	 {
		 [geofenceLocations removeObject:geofenceLocation];
		 
		 [_privateFences addObject:geofenceLocation];
		 
		 if (geofenceLocations.count == 0)
		 {
			 finished();
		 }
		 else
		 {
			 [self _addAllFences:geofenceLocations onCompletion:finished];
		 }
	 } 
						 failure:^(NSError *err)
	 {
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
			[profileArray addObject:categoryDictionary];
		}
	}
	
	return profileArray;
}

- (NSString *)_locationsStoragePath
{
	NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentsDirectories objectAtIndex:0];
	
	return [documentDirectory stringByAppendingPathComponent:@"profiles.archive"];
}



@end
