//
//  AppDelegate.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "FBConnect.h"
#import "Facebook+iCatalog.h"
#import "LoginViewController.h"
@class ViewController;
@class LoginViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate> {
Facebook *facebook;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (nonatomic, retain) Facebook *facebook;

@end
