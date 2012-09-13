//
//  LoginViewController.m
//  LikeMindedPeople
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
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
	
	_fbButton.layer.shadowColor = [[UIColor grayColor] CGColor];
	_fbButton.layer.shadowOpacity = 0.9;
	_fbButton.layer.shadowRadius = 2;
	_fbButton.layer.shadowOffset = CGSizeMake(2.0, 2.0);
	_fbButton.layer.masksToBounds = NO;
}

-(void)authorizeFacebook
{
    [_facebook authorize:nil];
}

- (IBAction)bypassFacebook
{
	AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate bypassFacebook];
}

@end
