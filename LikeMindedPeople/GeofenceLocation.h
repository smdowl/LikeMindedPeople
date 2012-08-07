//
//  GeofenceLocation.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class QLPlace;
@interface GeofenceLocation : NSObject <NSCoding, MKAnnotation>
{	
	long long _placeId;
	NSString *_geofenceName;
	
	int _peopleCount;
	float _rating;
	
	CLLocationCoordinate2D _location;
	CGFloat _radius;
}

@property (nonatomic, assign) long long placeId;
@property (nonatomic, strong) NSString *geofenceName;

@property (nonatomic) int peopleCount;
@property (nonatomic) float rating;

@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) CGFloat radius;

- (id)initWithPlace:(QLPlace *)place;

- (BOOL)containsPin:(CLLocationCoordinate2D)pin;
- (QLPlace *)place;

@end
