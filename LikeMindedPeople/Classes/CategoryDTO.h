//
//  CategoryDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CategoryDTO : NSObject
{
	NSString *_name;
	NSArray *_parentCategories;
}

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSArray *parentCategories;

@end
