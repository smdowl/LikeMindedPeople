//
//  SettingsViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 29/10/2012.
//
//

#import "SettingsViewController.h"
#import "DataModel.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

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
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.navigationController.presentingViewController action:@selector(dismissModalViewControllerAnimated:)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;

    // This is to set the title text to a color other than default white
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
//    titleLabel.backgroundColor = [UIColor clearColor];
//    titleLabel.text = @"Settings";
//    titleLabel.textAlignment = UITextAlignmentCenter;
//    titleLabel.textColor = [UIColor blackColor];
//    self.navigationItem.titleView = titleLabel;
    self.navigationItem.title = @"Settings";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showGimbalSettings:(id)sender
{
    [[[DataModel sharedInstance] coreConnector] showPermissionsFromViewController:self];
}

@end
