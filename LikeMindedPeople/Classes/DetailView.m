//
//  DetailView.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailView.h"
#import "RadiiResultDTO.h"

@implementation DetailView
@synthesize data = _data;

@synthesize titleLabel = _titleLabel;
@synthesize detailsView = _detailsView;

@synthesize presentUsersLabel = _presentUsersLabel;
@synthesize ratingLabel = _ratingLabel;
@synthesize interestsLabel = _interestsLabel;

@synthesize backButton = _backButton;

@synthesize isShowing = _isShowing;

- (void)setData:(RadiiResultDTO *)data
{
	_data = data;
	
	_titleLabel.text = data.businessTitle;
	_detailsView.text = data.description;
	_presentUsersLabel.text = [NSString stringWithFormat:@"%i", data.peopleCount];
	_ratingLabel.text = [NSString stringWithFormat:@"%0.2f%", 100*data.rating];
	
	// TODO: actually do this
	_interestsLabel.text = @"";
}

@end
