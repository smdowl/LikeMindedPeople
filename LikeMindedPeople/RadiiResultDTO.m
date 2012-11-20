//
//  RadiiResultDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadiiResultDTO.h"

@implementation RadiiResultDTO

- (CLLocationCoordinate2D)coordinate
{
	return _searchLocation;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@: %@, %@. %0.2f total people:%i people here now:%i interests:%@ (%f,%f)", _businessId, _businessTitle, _details, _rating, _peopleHistoryCount, _peopleNowCount, _relatedInterests, _searchLocation.latitude, _searchLocation.longitude];
}

@end
