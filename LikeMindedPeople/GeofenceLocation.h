//
//  GeofenceLocation.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class QLPlace;
@interface GeofenceLocation : NSObject
{
	QLPlace *_place;
	int _peopleCount;
	float _rating;
}

@property (nonatomic, strong) QLPlace *place;
@property (nonatomic) int peopleCount;
@property (nonatomic) float rating;

@property (readonly) CGFloat latitude;
@property (readonly) CGFloat longitude;
@property (readonly) CGFloat radius;

- (BOOL)containsPin:(CLLocation *)pin;

@end
