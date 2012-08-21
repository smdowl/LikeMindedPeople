//
//  HoursDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HoursDTO.h"

@implementation HoursDTO
@synthesize status = _status;
@synthesize isOpen = _isOpen;
@synthesize timeFrames = _timeFrames;

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@", _status, _timeFrames];
}

@end
