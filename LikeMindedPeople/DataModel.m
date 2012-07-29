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
- (void)_getPPOIList;
- (void)_removeAllPrivateFences;
- (void)_getPrivateFences;
- (void)_setPrivateFences:(NSArray *)geofences;
- (NSArray *)_flattenProfile:(PRProfile *)profile;
@end

@implementation DataModel

static DataModel *_sharedInstance = nil;

@synthesize contextCoreConnector;
@synthesize contextPlaceConnector;
@synthesize contextInterestsConnector;

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
	_currentLocation = [NSMutableArray array];
	
    [self.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *contextConnectorPermissions) 
	 {
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

- (void)getInfo
{
	[self.contextPlaceConnector allPrivatePointsOfInterestAndOnSuccess:^(NSArray *ppoi)
	 {
		 for (QLPlaceEvent *event in ppoi)
		 {
			 NSLog(@"%@", event);
		 }
	 } failure:^(NSError *err)
	 {
		 
	 }];
}

#pragma mark -
#pragma mark Geofence listening

- (void)didGetPlaceEvent:(QLPlaceEvent *)event
{	
	QLPlace *currentPlace;
	
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
			
			[_currentLocation insertObject:currentPlace atIndex:0];
			
			break;
			
		case QLPlaceEventTypeLeft:
			[_currentLocation removeObjectAtIndex:0];
			currentPlace = [_currentLocation objectAtIndex:0];
			break;
	}
	
	// TODO: Server, set current location
}

// Remove a private place
- (void)deletePlace:(long long)existingPlaceId
{
	[self.contextPlaceConnector deletePlaceWithId:existingPlaceId success:^()
	{
		// do something after place has been deleted
	}
										  failure:^(NSError *error) {
											  // failed with statusCode
										  }]; 
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
	NSLog(@"%@ %@", profile, [profile.attrs.allValues objectAtIndex:0]);
	
	[self _flattenProfile:profile];
	//	[ServiceAdapter uploadPointsOfInterest:<#(NSArray *)#> forUser:<#(NSString *)#> success:<#^(id)success#>
	
	// Add the new pois to the database
	[self _getPPOIList];
	
	// TODO: Upload to server 
	
	//	[ServiceAdapter uploadPointsOfInterest:<#(NSArray *)#> forUser:<#(NSString *)#> success:<#^(id)success#>
	
	/*
	 * Upload to server _ppoi
	 */ 
	
	// Get the current location to filter the results from the server
	CLLocationManager *manager = [[CLLocationManager alloc] init];
	CLLocation *location = [manager location];
	
	// TODO: Get list of geofences from the server
	[ServiceAdapter getGeofencesForUser:_userId atLocation:location success:^(NSArray *geofences)
	 {
		 [self _removeAllPrivateFences];
		 [self _setPrivateFences:geofences];
	 }];
}

#pragma mark -
#pragma mark QLContextCorePermissionsDelegate
- (void)subscriptionPermissionDidChange:(BOOL)subscriptionPermission
{
    if (subscriptionPermission)
    {
		[self setup];
		[self runStartUpSequence];
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
		 _privatePointsOfInterest = ppoi;
		 
		 for (QLPlace *point in ppoi)
		 {
			 NSLog(@"%@", point);
		 }
	 } failure:^(NSError *err)
	 {
		 
	 }];
}

- (void)test
{
	
}

- (void)_removeAllPrivateFences
{
	for (QLPlace *geofence in _privateFences)
	{
		[self.contextPlaceConnector deletePlaceWithId:geofence.id
											  success:^(void){} failure:^(NSError *err){}];
	}
	
	_privateFences = nil;
}

- (void)_getPrivateFences
{
	[self.contextPlaceConnector allPlacesAndOnSuccess:^(NSArray *allPlaces)
	 {
		 _privateFences = [NSMutableArray arrayWithArray:allPlaces];
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
		 } failure:^(NSError *err){}];
		
	}
}

- (NSArray *)flattenProfile:(PRProfile *)profile
{
	NSMutableArray *profileArray = [NSMutableArray array];
	for (PRProfileAttribute *attr in profile.attrs)
	{
		for (PRAttributeCategory *cat in attr.attributeCategories)
		{
			NSDictionary *categoryDictionary = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithDouble:cat.likelihood] forKey:cat.key];
			[profileArray addObject:categoryDictionary];
		}
	}
	
	return profileArray;
}

@end
