//
//  LocationDetailsDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HoursDTO;
@interface LocationDetailsDTO : NSObject
{
	NSString *_name;
	NSString *_description;	
    NSString *_address;
    
	NSArray *_cateogories;
	
	HoursDTO *_hours;
	
	NSString *_menuURL;
	
	NSUInteger _currentPeopleCount;
	
	CGFloat _rating;
}

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *description;
@property (nonatomic,strong) NSString *address;

@property (nonatomic,strong) NSArray *categories;

@property (nonatomic,strong) HoursDTO *hours;

@property (nonatomic,strong) NSString *menuURL;

@property (nonatomic) NSUInteger currentPeopleCount;

@property (nonatomic) CGFloat rating;

@end
