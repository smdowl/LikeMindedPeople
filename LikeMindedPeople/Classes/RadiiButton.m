//
//  RadiiButton.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadiiButton.h"

@interface RadiiButton (PrivateUtilities)
- (void)_setup;
@end

@implementation RadiiButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self _setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self _setup];
}

- (void)_setup
{
	UIImage *buttonNormal = [[UIImage imageNamed:@"button1.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[self setBackgroundImage:buttonNormal forState:UIControlStateNormal];
	
	UIImage *buttonHighlighted = [[UIImage imageNamed:@"button2.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[self setBackgroundImage:buttonHighlighted forState:UIControlStateHighlighted];
	
	UIImage *buttonSelected = [[UIImage imageNamed:@"button2.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	[self setBackgroundImage:buttonSelected forState:UIControlStateSelected];
    
    self.titleLabel.textColor = [UIColor orangeColor];
}

@end
