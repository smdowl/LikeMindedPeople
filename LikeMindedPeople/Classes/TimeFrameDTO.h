//
//  TimeFrameDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeFrameDTO : NSObject
{
	NSString *_dayRange;	// A string representing the days represented by this timeframe
	NSArray *_openingTimes;	// An array of string for what time it is open during the dayRange iVar
	
	BOOL _includesToday;	// Whether this timeframe included today
}

@property (nonatomic,strong) NSString *dayRange;
@property (nonatomic,strong) NSArray *openingTimes;

@property (nonatomic) BOOL includesToday;

@end
