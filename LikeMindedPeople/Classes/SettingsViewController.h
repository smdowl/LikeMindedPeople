//
//  SettingsViewController.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 29/10/2012.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingsViewController : UIViewController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

- (IBAction)showGimbalSettings:(id)sender;

@end
