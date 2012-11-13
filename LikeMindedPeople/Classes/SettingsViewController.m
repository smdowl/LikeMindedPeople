//
//  SettingsViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 29/10/2012.
//
//

#import "SettingsViewController.h"
#import "DataModel.h"
#import "RDRadiiManager.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.navigationController.presentingViewController action:@selector(dismissModalViewControllerAnimated:)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.title = @"Settings";
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
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)rateAppButtonPunched:(id)sender
{
    [RD_MANAGER rateAppInStore];
}

@end
