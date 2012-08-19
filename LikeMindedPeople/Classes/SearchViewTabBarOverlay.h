//
//  SearchViewTabBarOverlay.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewTabBarOverlay : UIView
{
	NSArray *_siblingViews;
}

@property (nonatomic, strong) NSArray *siblingViews;

@end
