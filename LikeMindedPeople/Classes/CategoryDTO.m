//
//  CategoryDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CategoryDTO.h"

@implementation CategoryDTO
@synthesize name = _name;
@synthesize parentCategories = _parentCategories;

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ parents:%@", _name, _parentCategories];
}

@end
