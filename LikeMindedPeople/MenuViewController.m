//
//  MenuViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MenuViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController
@synthesize menuView = _menuView;
@synthesize menuURLString = _menuURLString;

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
    // Do any additional setup after loading the view from its nib.
	
	NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:_menuURLString]];
	[_menuView loadRequest:urlRequest];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)setMenuURLString:(NSString *)menuURLString
{
	_menuURLString = menuURLString;
	
	NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:menuURLString]];
	[_menuView loadRequest:urlRequest];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	NSLog(@"%@", webView);
}

#pragma mark -
#pragma mark IBActions

- (IBAction)hideMenu
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
