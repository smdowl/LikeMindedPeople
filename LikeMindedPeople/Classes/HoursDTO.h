//
//  HoursDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HoursDTO : NSObject
{
	NSString *_status;
	BOOL _isOpen;
	NSArray *_timeFrames;
}

@property (nonatomic,strong) NSString *status;
@property (nonatomic) BOOL isOpen;
@property (nonatomic,strong) NSArray *timeFrames;

@end
