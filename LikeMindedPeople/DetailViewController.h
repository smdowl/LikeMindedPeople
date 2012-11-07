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

    // We need a ref to the scroll view to prevent a ui glitch after presenting views modally
    UIScrollView *_containerView;
    
    UIImageView *_thumbnailImage;
    
	UILabel *_titleLabel;
    UILabel *_subcategoryLabel;
//    A label to represent the price. Needs making!
//    PriceLabel *_priceLabel;
    
	UITextView *_detailsView;
	
	UILabel *_presentUsersLabel;
	UILabel *_ratingLabel;
    
    // A label to display the most common interests
	UILabel *_interestsLabel;
	
    UITextView *_addressView;
    UILabel *_phoneNumberLabel;
    
    // A view to gray out the screen when loading details
	UIView *_loadingDetailsView;
	UIActivityIndicatorView *_activityIndicator;
    
    BOOL _downloadingDetails;
}

@property (nonatomic,strong) RadiiResultDTO *data;
@property (nonatomic,strong) LocationDetailsDTO *locationDetails;

@property (nonatomic,strong) IBOutlet UIScrollView *containerView;

@property (nonatomic,strong) IBOutlet UIImageView *thumbnailImage;

@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) IBOutlet UILabel *subcategoryLabel;
@property (nonatomic,strong) IBOutlet UITextView *detailsView;

@property (nonatomic,strong) IBOutlet UILabel *presentUsersLabel;
@property (nonatomic,strong) IBOutlet UILabel *ratingLabel;
// Not yet implemented
@property (nonatomic,strong) IBOutlet UILabel *interestsLabel;

@property (nonatomic,strong) IBOutlet UITextView *addressView;
@property (nonatomic,strong) IBOutlet UILabel *phoneNumberLabel;

- (void)failedToLoadDetails;

- (IBAction)rateUp:(id)sender;
- (IBAction)rateDown:(id)sender;

- (IBAction)share:(id)sender;

- (IBAction)callBusiness:(id)sender;
- (IBAction)directionsBusiness:(id)sender;
- (IBAction)menuBusiness:(id)sender;

@end
