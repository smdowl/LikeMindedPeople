//
//  DetailView.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RadiiResultDTO, LocationDetailsDTO;
@interface DetailView : UIView
{
	RadiiResultDTO *_data;
	LocationDetailsDTO *_locationDetails;
	
	// UI components
	UILabel *_titleLabel;
	UITextView *_detailsView;
	
	UILabel *_presentUsersLabel;
	UILabel *_ratingLabel;
	UILabel *_interestsLabel;
	
	UIView *_loadingDetailsView;
	UIActivityIndicatorView *_activityIndicator;
	
	UIButton *_backButton;
	
	UIView *_gestureRecognizerView;
	
	UIButton *_menuButton;
	
	UIButton *_directionsButton;
	UILabel *_directionsLabel;
	NSDictionary *_directionsDictionary;
	
	BOOL _isShowing;
	BOOL _downloadingDetails;
}


@property (nonatomic,strong) RadiiResultDTO *data;
@property (nonatomic,strong) LocationDetailsDTO *locationDetails;

@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) IBOutlet UITextView *detailsView;

@property (nonatomic,strong) IBOutlet UILabel *presentUsersLabel;
@property (nonatomic,strong) IBOutlet UILabel *ratingLabel;
@property (nonatomic,strong) IBOutlet UILabel *interestsLabel;

@property (nonatomic,strong) IBOutlet UIView *loadingDetailsView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic,strong) IBOutlet UIButton *backButton;

@property (nonatomic,strong) IBOutlet UIView *gestureRecognizerView;

@property (nonatomic,strong) IBOutlet UIButton *menuButton;

@property (nonatomic,strong) IBOutlet UIButton *directionsButton;
@property (nonatomic,strong) IBOutlet UILabel *directionsLabel;
@property (nonatomic,strong) NSDictionary *directionsDictionary;

@property (nonatomic) BOOL isShowing;

@property (nonatomic, assign) BOOL downloadingDetails;

- (IBAction)selectButton:(UIButton *)button;
- (void)failedToLoadDetails;

@end
