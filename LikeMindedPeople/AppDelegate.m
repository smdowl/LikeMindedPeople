//
//  AppDelegate.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "FBConnect.h"
#import "Facebook+iCatalog.h"
#import "NSObject+DTRuntime.h"
#import "ServiceAdapter.h"
#import "LoginViewController.h"
#import "MapViewController.h"
#import "DetailViewController.h"
#import "Flurry.h"

#define CORNER_RADIUS 5.0

@implementation AppDelegate

@synthesize window = _window;
@synthesize facebook = _facebook;
@synthesize loginViewController = _loginViewController;


+ (void)initialize
{
    // disable Facebook SSO
    // This is a hack that is supposed to avoid going to Safari to authenticate via Facebook.
    // It doesn't seem to be helping, but I'll leave it here in case I want to revisit it. For the moment,
    // I recompiled the library to, hopefully, not go through Safari.
    //[Facebook swizzleMethod:@selector(authorize:) withMethod:@selector(authorize_noSSO:)];
}

#pragma mark -
#pragma mark Application Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
	
    [Flurry startSession:@"PBVKM874ZTRJX42BSC48"];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
	CAShapeLayer *mask = [CAShapeLayer layer];
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,20,320,480) cornerRadius:CORNER_RADIUS];
	mask.path = maskPath.CGPath;
	
	// Round the corners of the window. The rounded top corners are hidden by the status bar so need to be done separately
    [self.window.layer setCornerRadius:5.0];
//	self.window.layer.mask = mask;
	[self.window.layer setMasksToBounds:YES];
	
    // Just for testing the service adapter through NSLogs
    //[ServiceAdapter testService];
    
	_mapViewController = [[MapViewController alloc] initWithNibName:nil bundle:nil];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_mapViewController];
    // FB Integration fb123987074412482
//    _facebook = [[Facebook alloc] initWithAppId:@"123987074412482" andDelegate:self];
    _facebook = [[Facebook alloc] initWithAppId:@"276594672455627" andDelegate:self];	
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        _facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        _facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    if (![_facebook isSessionValid]) {
        NSLog(@"Start facebook authorize");
		_loginViewController = [[LoginViewController alloc] initWithNibName:nil bundle:nil];    
		_loginViewController.facebook = _facebook;
        self.window.rootViewController = _loginViewController;
    }
	else
	{
		[_facebook requestWithGraphPath:@"me" andDelegate:self];
		self.window.rootViewController = _mapViewController;
//        self.window.rootViewController = navController;
	}
	
    [self.window makeKeyAndVisible];

//	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause	 ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[DataModel sharedInstance] close];

	if (self.window.rootViewController == _mapViewController)
	{
		[_mapViewController viewDidDisappear:NO];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	if (self.window.rootViewController == _mapViewController)
	{
		[_mapViewController viewDidAppear:NO];
	}
	
	[[[DataModel sharedInstance] coreConnector] checkStatusAndOnEnabled:^(QLContextConnectorPermissions *permissions)
	 {
		 // Make the call that updates all the internal variables for the model
		 [[DataModel sharedInstance] runStartUpSequence];	 
	 }
															   disabled:^(NSError *error)
	 {
		 
	 }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{	
	// If the gimbal SDK is enabled
	[[[DataModel sharedInstance] coreConnector] checkStatusAndOnEnabled:^(QLContextConnectorPermissions *permissions)
	 {
		 // Make the call that updates all the internal variables for the model
		 [[DataModel sharedInstance] runStartUpSequence];	 
	 }
															   disabled:^(NSError *error)
	 {
		 
	 }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)bypassFacebook
{
	self.window.rootViewController = _mapViewController;
	
	[[DataModel sharedInstance] setAuthorized:YES];
	[[DataModel sharedInstance] runStartUpSequence];
}

#pragma matk -
#pragma mark Flurry Analytics

void uncaughtExceptionHandler(NSException *exception)
{
    [Flurry logError:@"Uncaught" message:@"Crash!" exception:exception];
}

#pragma mark -- FB integration
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"openURL");
    return [_facebook handleOpenURL:url];
}

- (void)fbDidLogin {
    NSLog(@"fbDidLogin, self=%@", self);

    // For grabbing the facebook ID -- makes a request that returns asynchronously below
    [_facebook requestWithGraphPath:@"me" andDelegate:self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[_facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize]; 
    self.window.rootViewController = _mapViewController;
	
	[[DataModel sharedInstance] setAuthorized:YES];
	[[DataModel sharedInstance] runStartUpSequence];
    
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    NSLog(@"fbDidNotLogin");
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not connect to facebook" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)fbDidLogout
{
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
	
	// TODO: Why display something else?
//    [_loginViewController presentModalViewController:_loginViewController.fbLogin animated:NO];
}

- (void)fbExpiresAt
{
    
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt
{
    
}
- (void) fbSessionInvalidated
{
    
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    NSString *facebookId = [result objectForKey:@"id"];
    NSString *userName = [result objectForKey:@"name"];
    NSString *userEmail = [result objectForKey:@"email"];
    NSLog(@"facebookID = %@, userName = %@, userEmail = %@", facebookId, userName, userEmail);
    //do whatever you need to do with this info next
    //(ie. save to db, pass to user singleton, whatever)
    [[DataModel sharedInstance] setUserId:facebookId];
	[[DataModel sharedInstance] setUserName:userName];
}

@end
