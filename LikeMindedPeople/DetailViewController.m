//
//  DetailViewController.m
//  LikeMindedPeople
//
//  Created by Shaun on 18/10/2012.
//
//

#import "DetailViewController.h"
#import "RadiiResultDTO.h"
#import "LocationDetailsDTO.h"
#import "ServiceAdapter.h"
#import "DataModel.h"

@interface DetailViewController (PrivateUtilities)

@end

@implementation DetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Getters and setters

- (void)setData:(RadiiResultDTO *)data
{
	_data = data;
	
	_locationDetails = nil;
    _downloadingDetails = NO;
	
	_titleLabel.text = data.businessTitle;
	_detailsView.text = data.details;
    //	_presentUsersLabel.text = [NSString stringWithFormat:@"%i", data.peopleCount];
	_presentUsersLabel.text = @"-";
    //	_ratingLabel.text = @"-";
	_ratingLabel.text = [NSString stringWithFormat:@"%0.0f%%", 100*data.rating];
	
	// TODO: actually do this
	_interestsLabel.text = @"";
	
	_menuButton.hidden = YES;
	
	_loadingDetailsView.hidden = NO;
	[_activityIndicator startAnimating];
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
    //		_ratingLabel.text = [NSString stringWithFormat:@"%0.0f%%", locationDetails.rating*100];
    //	}
}

- (void)failedToLoadDetails
{
	_loadingDetailsView.hidden = YES;
	[_activityIndicator stopAnimating];
}

@end

@implementation DetailViewController (PrivateUtilities)

- (void)_startDownloadingDetails
{
		_downloadingDetails = YES;
	
    DetailViewController *strongSelf = self;
    
		[ServiceAdapter getLocationDetails:_data
									userId:[[DataModel sharedInstance] apiId]
								   success:^(LocationDetailsDTO *details)
		 {
			 if (strongSelf)
				 self.locationDetails = details;
		 }
								   failure:^(NSError *error)
		 {
             //			 [[[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Problem getting details for location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
             if (strongSelf)
                 [strongSelf failedToLoadDetails];
		 }];
}


@end
