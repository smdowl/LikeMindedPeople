//
//  DataModel.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ContextCore/QLContextCoreConnector.h>
#import <ContextLocation/QLContextPlaceConnector.h>
#import <ContextProfiling/PRContextInterestsConnector.h>
#import <CoreLocation/CoreLocation.h>
#import "GeofenceLocation.h"

@class QLPlace;
@interface DataModel : NSObject <QLContextCorePermissionsDelegate, QLContextPlaceConnectorDelegate, PRContextInterestsDelegate, CLLocationManagerDelegate>
{
	NSString *_userId;	// In out app is going to be the fb ID. Used to identify you on the server
	
	QLContextCoreConnector *_coreConnector;
	QLContextPlaceConnector *_placeConnector;
	PRContextInterestsConnector *_interestsConnector;

	CLLocationManager *_locationManager;
	NSMutableArray *_locationListeners;

	// An array basically being used as a stack, pushing and popping from index 0
	NSMutableArray *_currentLocation;
	
	// Location arrays
	NSArray *_personalPointsOfInterest;
	NSMutableArray *_privateFences;
	
	// This is the fence that will be used to trigger when the local place geofences need to be refreshed
	GeofenceLocation *_geofenceRefreshLocation;
	
	BOOL _settingUp; // Is the model in the process of setting up already?
}

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) QLContextCoreConnector *coreConnector;
@property (nonatomic, strong) QLContextPlaceConnector *placeConnector;
@property (nonatomic, strong) PRContextInterestsConnector *interestsConnector;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, readonly) QLPlace *currentLocation;

@property (nonatomic, readonly) NSArray *personalPointsOfInterest;
@property (nonatomic, readonly) NSArray *privateFences;
@property (nonatomic, readonly) GeofenceLocation *geofenceRefreshLocation;

+ (DataModel *)sharedInstance;
- (void)getPPOIInfo;
- (void)runStartUpSequence;

- (void)addLocationListener:(id<CLLocationManagerDelegate>)listener;
- (void)removeLocationListener:(id<CLLocationManagerDelegate>)listener;

- (NSArray *)getAllGeofenceRegions;
- (void)updateGeofenceRefreshLocation;
- (void)close;

@end
