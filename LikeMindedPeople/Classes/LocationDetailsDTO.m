//
//  LocationDetailsDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationDetailsDTO.h"

@implementation LocationDetailsDTO
@synthesize name = _name;
@synthesize description = _description;
@synthesize categories = _categories;
@synthesize hours = _hours;
@synthesize menuURL = _menuURL;
@synthesize currentPeopleCount = _currentPeopleCount;
@synthesize rating = _rating;

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ categories:%@ hours:%@ menu:%@ %i %f", _name, _description, _categories, _hours, _menuURL, _currentPeopleCount, _rating];
}

@end
