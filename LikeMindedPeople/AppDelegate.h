//
//  AppDelegate.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "Facebook+iCatalog.h"
#import "DataModel.h"

@class ViewController;
@class LoginViewController;
@class MapViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate, FBRequestDelegate, FBSessionDelegate> 
{	
	LoginViewController *_loginViewController;
	Facebook *_facebook;
	MapViewController *_mapViewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (nonatomic, retain) Facebook *facebook;

- (void)bypassFacebook;

@end
