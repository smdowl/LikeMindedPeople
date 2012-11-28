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
#import "MenuViewController.h"
#import "RDFacebookManager.h"
#import "CategoryDTO.h"
#import "RadiiButton.h"


@interface DetailViewController (PrivateUtilities)
- (void)_startDownloadingDetails;
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
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
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
	_ratingLabel.text = [NSString stringWithFormat:@"%0.2f", data.rating];
#warning TODO
	// TODO: actually do this
	_interestsLabel.text = @"";
    
	_loadingDetailsView.hidden = NO;
    
    [self _startDownloadingDetails];
    
	[_activityIndicator startAnimating];
}

- (void)setLocationDetails:(LocationDetailsDTO *)locationDetails
{
#warning TODO
	// TODO: Took this out for want of a better system for telling if the details apply to this page or not
    //	if ([locationDetails.name isEqualToString:_data.businessTitle])
    //	{
    _loadingDetailsView.hidden = YES;
    [_activityIndicator stopAnimating];
    
    _locationDetails = locationDetails;
    
    _addressView.text = _locationDetails.address;
    
    _presentUsersLabel.text = [NSString stringWithFormat:@"%i", locationDetails.currentPeopleCount];
    
    _phoneNumberLabel.text = locationDetails.phoneNumber;
    CategoryDTO *category = [locationDetails.categories objectAtIndex:0];
    _subcategoryLabel.text = category.name;
    
    //		_ratingLabel.text = [NSString stringWithFormat:@"%0.0f%%", locationDetails.rating*100];
    //	}
}

- (void)failedToLoadDetails
{
	_loadingDetailsView.hidden = YES;
	[_activityIndicator stopAnimating];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)rateUp:(id)sender
{
    [ServiceAdapter ratePlace:_data user:@"1" up:true];
    [self.thumbsUpButton setSelected:YES];
    [self.thumbsDownButton setSelected:NO];
}

- (IBAction)rateDown:(id)sender
{
    [ServiceAdapter ratePlace:_data user:@"1" up:false];
    [self.thumbsDownButton setSelected:YES];
    [self.thumbsUpButton setSelected:NO];
}

- (IBAction)share:(id)sender
{
    [FACEBOOK_MANAGER postToWallWithTitle:@"Titulo teste" AndMessage:@"message teste" AndPicture:@"teste"];
}

- (IBAction)callBusiness:(id)sender
{
    UIAlertView * alertView;
        
    NSString *currentModel = [[UIDevice currentDevice] model];
    if (![currentModel isEqualToString:@"iPhone"])
    {
        alertView = [[UIAlertView alloc] initWithTitle:nil
                                               message:NSLocalizedString(@"_detailView_phonecall_iPad_message", @"")
                                              delegate:nil
                                     cancelButtonTitle:NSLocalizedString(@"_alertView_ok", @"")
                                     otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    if (_locationDetails.phoneNumber)
    {
        NSString *callString = [NSString stringWithFormat:@"tel://%@", _locationDetails.phoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callString]];
    }
    else
    {
        alertView = [[UIAlertView alloc] initWithTitle:nil
                                               message:@"No phone number available"
                                              delegate:nil
                                     cancelButtonTitle:NSLocalizedString(@"_alertView_ok", @"")
                                     otherButtonTitles:nil];
        [alertView show];
    }
    
}

- (IBAction)directionsBusiness:(id)sender
{
    CLLocationCoordinate2D destination = CLLocationCoordinate2DMake(self.data.searchLocation.latitude, self.data.searchLocation.longitude);
    
    Class itemClass = [MKMapItem class];
    if (itemClass && [itemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:destination addressDictionary:nil]];
        toLocation.name = @"Destination";
        [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:currentLocation, toLocation, nil]
                       launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeDriving, [NSNumber numberWithBool:YES], nil]
                                                                 forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsShowsTrafficKey, nil]]];
        return;
    }
    
    NSMutableString *mapURL = [NSMutableString stringWithString:@"http://maps.google.com/maps?"];
    [mapURL appendFormat:@"saddr=Current Location"];
    [mapURL appendFormat:@"&daddr=%f,%f", destination.latitude, destination.longitude];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[mapURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (IBAction)menuBusiness:(id)sender
{
    MenuViewController *menuController = [[MenuViewController alloc] initWithNibName:nil bundle:nil];
    // If the location details have been set then use the url defined there. Otherwise, just pass nil so that the meny can present the no menu screen.
    menuController.menuURLString = _locationDetails ? _locationDetails.menuURL : nil;
    [self presentModalViewController:menuController animated:YES];
    
    // Animate the scroll view back to its original position to avoid a UI glitch
    [UIView animateWithDuration:1 animations:^()
     {
         _containerView.contentOffset = CGPointZero;
     }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == 666 && buttonIndex == 1)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://+33980980986"]];
	}
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
