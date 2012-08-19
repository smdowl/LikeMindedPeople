//
//  DetailView.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RadiiResultDTO;
@interface DetailView : UIView
{
	RadiiResultDTO *_data;
	
	// UI components
	UILabel *_titleLabel;
	UITextView *_detailsView;
	
	UILabel *_presentUsersLabel;
	UILabel *_ratingLabel;
	UILabel *_interestsLabel;
	
	UIButton *_backButton;
	
	UIView *_gestureRecognizerView;
	
	UIButton *_directionsButton;
	UILabel *_directionsLabel;
	NSDictionary *_directionsDictionary;
	
	BOOL _isShowing;
}


@property (nonatomic,strong) RadiiResultDTO *data;

@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) IBOutlet UITextView *detailsView;

@property (nonatomic,strong) IBOutlet UILabel *presentUsersLabel;
@property (nonatomic,strong) IBOutlet UILabel *ratingLabel;
@property (nonatomic,strong) IBOutlet UILabel *interestsLabel;

@property (nonatomic,strong) IBOutlet UIButton *backButton;

@property (nonatomic,strong) IBOutlet UIView *gestureRecognizerView;

@property (nonatomic,strong) IBOutlet UIButton *directionsButton;
@property (nonatomic,strong) IBOutlet UILabel *directionsLabel;
@property (nonatomic,strong) NSDictionary *directionsDictionary;

@property (nonatomic) BOOL isShowing;

@end
