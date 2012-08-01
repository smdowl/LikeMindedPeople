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
@interface DataModel : NSObject <QLContextCorePermissionsDelegate, QLContextPlaceConnectorDelegate, PRContextInterestsDelegate>
{
	NSString *_userId;	// In out app is going to be the fb ID. Used to identify you on the server
	
	NSArray *_placeEvents; // An array of all the previous events
	
	NSArray *_personalPointsOfInterest;
	
	// An array basically being used as a stack, pushing and popping from index 0
	NSMutableArray *_currentLocation;
//	NSArray *_allLocations;
	
	NSArray *_geofenceSearchLocations;
	
	NSMutableArray *_privateFences;
	
	int _failures;
}

@property (nonatomic, strong) QLContextCoreConnector *contextCoreConnector;
@property (nonatomic, strong) QLContextPlaceConnector *contextPlaceConnector;
@property (nonatomic, strong) PRContextInterestsConnector *contextInterestsConnector;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, readonly) NSArray *placeEvents;
@property (nonatomic, readonly) NSArray *personalPointsOfInterest;
@property (nonatomic, readonly) QLPlace *currentLocation;
@property (nonatomic, readonly) NSArray *privateFences;

+ (DataModel *)sharedInstance;
- (void)getInfo;
- (void)runStartUpSequence;
- (GeofenceLocation *)getInfoForPin:(CLLocationCoordinate2D)pin;

- (NSArray *)getAllGeofenceRegions;

@end
