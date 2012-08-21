//
//  TimeFrameDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TimeFrameDTO.h"

@implementation TimeFrameDTO
@synthesize dayRange = _dayRange;
@synthesize openingTimes = _openingTimes;
@synthesize includesToday = _includesToday;

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ today? %@", _dayRange, _openingTimes, _includesToday ? @"yes" : @"no"];
}

@end
