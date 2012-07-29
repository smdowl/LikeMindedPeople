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

@class QLPlace;
@interface DataModel : NSObject <QLContextCorePermissionsDelegate, QLContextPlaceConnectorDelegate, PRContextInterestsDelegate>
{
	NSString *_userId;
	
	NSArray *_placeEvents;
	
	NSArray *_privatePointsOfInterest;
	
	// An array basically being used as a stack, pushing and popping from index 0
	NSMutableArray *_currentLocation;
//	NSArray *_allLocations;
	
	NSMutableArray *_privateFences;
	
	BOOL _deletingPrivateFences;
}

@property (nonatomic, strong) QLContextCoreConnector *contextCoreConnector;
@property (nonatomic, strong) QLContextPlaceConnector *contextPlaceConnector;
@property (nonatomic, strong) PRContextInterestsConnector *contextInterestsConnector;

+ (DataModel *)sharedInstance;
- (void)setup;
- (void)getInfo;
- (void)runStartUpSequence;

@end
