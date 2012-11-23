//
//  LocationDetailsDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationDetailsDTO.h"

@implementation LocationDetailsDTO

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ categories:%@ hours:%@ menu:%@ %i %f", _name, _description, _categories, _hours, _menuURL, _currentPeopleCount, _rating];
}

@end
