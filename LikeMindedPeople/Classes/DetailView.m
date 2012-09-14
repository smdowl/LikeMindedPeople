//
//  DetailView.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailView.h"
#import "RadiiResultDTO.h"
#import "LocationDetailsDTO.h"

@implementation DetailView
@synthesize delegate = _delegate;

@synthesize bar = _bar;

@synthesize data = _data;
@synthesize locationDetails = _locationDetails;

@synthesize titleLabel = _titleLabel;
@synthesize detailsView = _detailsView;

@synthesize presentUsersLabel = _presentUsersLabel;
@synthesize ratingLabel = _ratingLabel;
@synthesize interestsLabel = _interestsLabel;

@synthesize loadingDetailsView = _loadingDetailsView;
@synthesize activityIndicator = _activityIndicator;

@synthesize backButton = _backButton;

@synthesize gestureRecognizerView = _gestureRecognizerView;

@synthesize menuButton = _menuButton;

@synthesize directionsButton = _directionsButton;
@synthesize directionsLabel = _directionsLabel;
@synthesize directionsDictionary = _directionsDictionary;

@synthesize isShowing = _isShowing;

@synthesize downloadingDetails = _downloadingDetails;

- (void)setDelegate:(id<SearchViewDelegate>)delegate
{
	_delegate = delegate;
	
	// We need a separate recognizer for each button (apparently)

	UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:_delegate action:@selector(toggleFullScreen)];
	[_bar addGestureRecognizer:recognizer];
}

- (void)setData:(RadiiResultDTO *)data
{
	_data = data;
	
	_locationDetails = nil;
	_downloadingDetails = NO;
	
	_titleLabel.text = data.businessTitle;
	_detailsView.text = data.details;
//	_presentUsersLabel.text = [NSString stringWithFormat:@"%i", data.peopleCount];
	_presentUsersLabel.text = @"-";
	_ratingLabel.text = @"-";
//	[NSString stringWithFormat:@"%0.0f%%", 100*data.rating];
	
	// TODO: actually do this
	_interestsLabel.text = @"";
	
	// Reset the directions button
	_directionsButton.hidden = NO;
	_directionsLabel.hidden = YES;
	
	_menuButton.hidden = YES;
	
	_loadingDetailsView.hidden = NO;
	[_activityIndicator startAnimating];
}

- (void)setDirectionsDictionary:(NSDictionary *)directionsDictionary
{
	_directionsDictionary = directionsDictionary;
	
	_directionsLabel.text = [NSString stringWithFormat:@"%@, %@", [_directionsDictionary objectForKey:@"distance"], [_directionsDictionary objectForKey:@"duration"]];
	
	_directionsButton.hidden = YES;
	_directionsLabel.hidden = NO;
}

- (void)setLocationDetails:(LocationDetailsDTO *)locationDetails
{
	// TODO: Took this out for want of a better system for telling if the details apply to this page or not
//	if ([locationDetails.name isEqualToString:_data.businessTitle])
//	{
		_loadingDetailsView.hidden = YES;
		[_activityIndicator stopAnimating];
		
		_locationDetails = locationDetails;
		
		if (locationDetails.menuURL)
			_menuButton.hidden = NO;
		
		_presentUsersLabel.text = [NSString stringWithFormat:@"%i", locationDetails.currentPeopleCount];
		_ratingLabel.text = [NSString stringWithFormat:@"%0.0f%%", locationDetails.rating*100];
//	}
}

- (IBAction)selectButton:(UIButton *)button
{
	button.selected = YES;
}

- (void)failedToLoadDetails
{
	_loadingDetailsView.hidden = YES;
	[_activityIndicator stopAnimating];
}

@end
