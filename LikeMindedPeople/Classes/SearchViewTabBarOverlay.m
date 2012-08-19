//
//  SearchViewTabBarOverlay.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchViewTabBarOverlay.h"

@implementation SearchViewTabBarOverlay
@synthesize siblingViews = _siblingViews;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark -
#pragma mark Touch Event Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UIView *view in _siblingViews)
	{
		UITouch *touch = [touches anyObject];
		if ([view pointInside:[touch locationInView:self] withEvent:event])
		{
			[self.superview touchesBegan:touches withEvent:event];	
			break;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UIView *view in _siblingViews)
	{
		UITouch *touch = [touches anyObject];
		if ([view pointInside:[touch locationInView:self] withEvent:event])
		{
			[self.superview touchesBegan:touches withEvent:event];	
			break;
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UIView *view in _siblingViews)
	{
		UITouch *touch = [touches anyObject];
		if ([view pointInside:[touch locationInView:self] withEvent:event])
		{
			[self.superview touchesBegan:touches withEvent:event];	
			break;
		}
	}
}

@end
