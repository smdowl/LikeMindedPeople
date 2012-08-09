//
//  RadiiResultDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadiiResultDTO.h"

@implementation RadiiResultDTO
@synthesize businessTitle = _businessTitle;
@synthesize details = _details;

@synthesize rating = _rating;
@synthesize peopleCount = _peopleCount;
@synthesize relatedInterests = _relatedInterests;

@synthesize searchLocation = _searchLocation;

- (CLLocationCoordinate2D)coordinate
{
	return _searchLocation;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, %@. %0.2f %i people %@ interests (%f,%f)", _businessTitle, _details, _rating, _peopleCount, _relatedInterests, _searchLocation.latitude, _searchLocation.longitude];
}

@end
