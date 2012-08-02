//
//  LoginViewController.m
//  LikeMindedPeople
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize facebook = _facebook;
@synthesize fbButton = _fbButton;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[_fbButton addTarget:self action:@selector(authorizeFacebook) forControlEvents:UIControlEventTouchUpInside];
}

-(void)authorizeFacebook
{
    [_facebook authorize:nil];
}

@end
