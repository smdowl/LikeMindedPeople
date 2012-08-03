//
//  RadiiResultDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadiiResultDTO.h"
#import "GeofenceLocation.h"

@implementation RadiiResultDTO
@synthesize businessTitle = _businessTitle;
@synthesize description = _description;

@synthesize rating = _rating;
@synthesize peopleCount = _peopleCount;
@synthesize relatedInterests = _relatedInterests;

@synthesize geofence = _geofence;
@synthesize searchLocation = _searchLocation;

- (CLLocationCoordinate2D)coordinate
{
	if (_geofence)
	{
		return _geofence.coordinate;		
	}
	else
	{
		return _searchLocation;
	}
}

@end
