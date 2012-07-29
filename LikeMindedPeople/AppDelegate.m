//
//  AppDelegate.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "FBConnect.h"
#import "Facebook+iCatalog.h"
#import "NSObject+DTRuntime.h"


@implementation AppDelegate

@synthesize viewController;

@synthesize window = _window;
@synthesize facebook;
@synthesize loginViewController;


+ (void)initialize
{
    // disable Facebook SSO
    // This is a hack that is supposed to avoid going to Safari to authenticate via Facebook.
    // It doesn't seem to be helping, but I'll leave it here in case I want to revisit it. For the moment,
    // I recompiled the library to, hopefully, not go through Safari.
    //[Facebook swizzleMethod:@selector(authorize:) withMethod:@selector(authorize_noSSO:)];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];    

//    [facebook authorize:nil];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    
    
    // FB Integration fb123987074412482
    facebook = [[Facebook alloc] initWithAppId:@"123987074412482" andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    if (![facebook isSessionValid]) {
        NSLog(@"Start facebook authorize");
        self.window.rootViewController = loginViewController;
//        [self.viewController presentModalViewController:loginViewController animated:NO];
//        [facebook authorize:nil];
    }
    [facebook requestWithGraphPath:@"me" andDelegate:self];

    return YES;
}
-(void)fbAuth {
    
    [facebook authorize:nil];
}
#pragma mark -- FB integration
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"openURL");
    return [facebook handleOpenURL:url];
}

- (void)fbDidLogin {
    NSLog(@"fbDidLogin, self=%@", self);

    // For grabbing the facebook ID -- makes a request that returns asynchronously below
    [facebook requestWithGraphPath:@"me" andDelegate:self];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    self.window.rootViewController = viewController;
    
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    NSLog(@"fbDidNotLogin");
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
    [self.viewController presentModalViewController:self.viewController.fbLogin animated:NO];
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
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//	DataModel *dataModel = [DataModel sharedInstance];
//	
//	// Make the call that updates all the internal variables for the model
//	[dataModel runStartUpSequence];	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
