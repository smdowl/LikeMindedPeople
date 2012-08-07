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
@synthesize placeId = _placeId;
@synthesize geofenceName = _geofenceName;

@synthesize peopleCount = _peopleCount;
@synthesize rating = _rating;

@synthesize location = _location;
@synthesize radius = _radius;

- (id)initWithPlace:(QLPlace *)place
{
	self = [super init];
	
	if (self)
	{
		if (place)
		{
			_placeId = place.id;
			_geofenceName = place.name;
			
			QLGeoFenceCircle *circle = (QLGeoFenceCircle *)place.geoFence;
			_location.latitude = circle.latitude;
			_location.longitude = circle.longitude;
			_radius = circle.radius;
		}
	}
	
	return self;
}

- (id)init
{
	return [self initWithPlace:nil];
}

- (BOOL)containsPin:(CLLocationCoordinate2D)pin
{		
	CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:_location radius:_radius identifier:@"region"];
		
	return [region containsCoordinate:pin];
}

- (QLPlace *)place
{
	QLPlace *place = [[QLPlace alloc] init];

	place.id = _placeId;
	place.name = _geofenceName;
	
	QLGeoFenceCircle *circle = [[QLGeoFenceCircle alloc] init];
	circle.latitude = _location.latitude;
	circle.longitude = _location.longitude;
	circle.radius = _radius;
	
	place.geoFence = circle;
	
	return place;
}

- (BOOL)isEqual:(id)object
{
	if (![object isKindOfClass:[GeofenceLocation class]])
	{
		return NO;
	}
	else
	{
		GeofenceLocation *otherLocation = (GeofenceLocation *)object;
		
		// Not including _placeId because sometimes this isn't availible
		// Also only checking the first 6 decimal places are the smae with the lat and long
//		return _placeId == otherLocation.placeId &&
		
		return [_geofenceName isEqualToString:otherLocation.geofenceName] &&
		_peopleCount == otherLocation.peopleCount &&
		_rating == otherLocation.rating &&
		floor(_location.latitude*pow(10,6)) == floor(otherLocation.location.latitude * pow(10,6)) && 
		floor(_location.longitude*pow(10,6)) == floor(otherLocation.location.longitude*pow(10,6)) &&
		floor(_radius) == floor(otherLocation.radius);
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%lli: %@ %i people %0.2f% ( %f, %f ) r=%f",_placeId,_geofenceName,_peopleCount,_rating,_location.latitude, _location.longitude, _radius];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if (self)
	{
		_placeId = [[aDecoder decodeObjectForKey:@"placeId"] longLongValue];
		_geofenceName = [aDecoder decodeObjectForKey:@"geofenceName"];
		
		_peopleCount = [[aDecoder decodeObjectForKey:@"peopleCount"] intValue];
		_rating = [[aDecoder decodeObjectForKey:@"rating"] floatValue];
		
		_location.latitude = [[aDecoder decodeObjectForKey:@"latitude"] floatValue];
		_location.longitude = [[aDecoder decodeObjectForKey:@"longitude"] floatValue];
		_radius = [[aDecoder decodeObjectForKey:@"radius"] floatValue];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:[NSNumber numberWithLongLong:_placeId] forKey:@"placeId"];
	[aCoder encodeObject:_geofenceName forKey:@"geofenceName"];
	
	[aCoder encodeObject:[NSNumber numberWithInt:_peopleCount] forKey:@"peopleCount"];
	[aCoder encodeObject:[NSNumber numberWithFloat:_rating] forKey:@"rating"];
	
	[aCoder encodeObject:[NSNumber numberWithFloat:_location.latitude] forKey:@"latitude"];
	[aCoder encodeObject:[NSNumber numberWithFloat:_location.longitude] forKey:@"longitude"];
	[aCoder encodeObject:[NSNumber numberWithFloat:_radius] forKey:@"radius"];
}

#pragma mark -
#pragma mark MKAnnotation protocol

- (CLLocationCoordinate2D)coordinate
{	
	return _location;
}

- (NSString *)title
{
	return [NSString stringWithFormat:@"Rating: %f", _rating];
}

@end
