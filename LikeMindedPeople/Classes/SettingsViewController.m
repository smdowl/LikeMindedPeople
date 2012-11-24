//
//  SettingsViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 29/10/2012.
//
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "DataModel.h"
#import "RDRadiiManager.h"

@interface SettingsViewController ()
- (IBAction)logout;
@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.navigationController.presentingViewController action:@selector(dismissModalViewControllerAnimated:)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.title = @"Settings";
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor clearColor], UITextAttributeTextColor,
                                               [UIColor clearColor], UITextAttributeTextShadowColor,
                                               nil];
    
    self.navigationController.navigationBar.titleTextAttributes = navbarTitleTextAttributes;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navBarBackground.png"]];
    [self.navigationController.navigationBar setBackgroundImage:imageView.image forBarMetrics:UIBarMetricsDefault];
}

- (IBAction)logout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log out"
                                                    message:@"Are you sure you want to log out?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles: @"Yes",nil];
    [alert show];
}

- (IBAction)showGimbalSettings:(id)sender
{
    [[[DataModel sharedInstance] coreConnector] showPermissionsFromViewController:self];
}

- (IBAction)sendEmail:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"User feedback"];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"radiiapp@gmail.com", nil];
        [mailer setToRecipients:toRecipients];
//        [mailer setMessageBody:emailBody isHTML:NO];
        mailer.modalPresentationStyle = UIModalPresentationPageSheet; // in order to work on iPads
        [self presentModalViewController:mailer animated:YES];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                    message:@"Your device doesn't support the composer sheet"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)rateAppButtonPunched:(id)sender
{
    [RD_MANAGER rateAppInStore];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[DataModel sharedInstance] deleteUserInfo];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] returnToLoginScreen];
    }
}

@end
