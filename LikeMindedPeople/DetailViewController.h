//
//  DetailViewController.h
//  LikeMindedPeople
//
//  Created by Shaun on 18/10/2012.
//
//

#import <UIKit/UIKit.h>

@class RadiiResultDTO, LocationDetailsDTO;
@interface DetailViewController : UIViewController
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
	
	UIButton *_menuButton;
    
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

@property (nonatomic,strong) IBOutlet UIButton *menuButton;

@property (nonatomic) BOOL downloadingDetails;

- (void)failedToLoadDetails;
- (IBAction)cancel;

@end
