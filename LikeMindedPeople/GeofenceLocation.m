//
//  GeofenceLocation.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeofenceLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <ContextLocation/QLPlace.h>
#import <ContextLocation/QLGeofenceCircle.h>

@implementation GeofenceLocation
@synthesize place = _place;
@synthesize peopleCount = _peopleCount;
@synthesize rating = _rating;

- (CGFloat)latitude
{
	QLGeoFenceCircle *circle = (QLGeoFenceCircle *)_place.geoFence;
	return circle.latitude;	
}

- (CGFloat)longitude
{
	QLGeoFenceCircle *circle = (QLGeoFenceCircle *)_place.geoFence;
	return circle.longitude;	
}

- (CGFloat)radius
{
	QLGeoFenceCircle *circle = (QLGeoFenceCircle *)_place.geoFence;
	return circle.radius;	
}

- (BOOL)containsPin:(CLLocationCoordinate2D)pin
{
	QLGeoFenceCircle *circle = (QLGeoFenceCircle *)_place.geoFence;
	
	CLLocationCoordinate2D regionCenter;
	regionCenter.longitude = circle.longitude;
	regionCenter.latitude = circle.latitude;
	
	CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:regionCenter radius:circle.radius identifier:nil];
	return [region containsCoordinate:pin];
}

@end
