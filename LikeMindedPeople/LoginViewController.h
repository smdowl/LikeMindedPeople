//
//  LoginViewController.h
//  LikeMindedPeople
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Facebook;
@interface LoginViewController : UIViewController 
{
	Facebook *_facebook;
	UIButton *_fbButton;
}

@property (nonatomic, strong) Facebook *facebook;
@property (nonatomic, strong) IBOutlet UIButton *fbButton;

- (void)authorizeFacebook;

@end
