//
//  RDFacebookManager.m
//  LikeMindedPeople
//
//  Created by Lucas Coelho on 11/13/12.
//
//

#import "RDFacebookManager.h"
#import "SynthesizeSingleton.h"

#define FACEBOOK_APP_ID @"276594672455627"

NSString * const kFacebookManagerLoginSucceed       = @"FacebookManagerLoginSucceed";
NSString * const kFacebookManagerLoginFailed        = @"FacebookManagerLoginFailed";
NSString * const kFacebookManagerCheckinSucceed     = @"FacebookManagerCheckinSucceed";
NSString * const kFacebookManagerCheckinFailed      = @"FacebookManagerCheckinFailed";
NSString * const kFacebookManagerWallPostSucceed     = @"FacebookManagerWallPostSucceed";
NSString * const kFacebookManagerWallPostFailed      = @"FacebookManagerWallPostFailed";

NSString * const kFacebookManagerLogOutSucceed      = @"FacebookManagerLogOutSucceed";

@implementation RDFacebookManager

@synthesize facebook                = _facebook;

SYNTHESIZE_SINGLETON_FOR_CLASS(RDFacebookManager);

#pragma mark -
#pragma mark Facebook Basics

-(BOOL) loginToFacebookIfNeeded {
    
    self.facebook = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID andDelegate:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        if ( [self.facebook.accessToken length] == 0){
            // to make the session invalid
            self.facebook.accessToken = nil;
        }
        
        self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
        
    }
    
    if (![self.facebook isSessionValid]) {
        NSArray *permissions = [NSArray arrayWithObjects: @"user_checkins", @"friends_checkins", @"publish_checkins", nil];
        [self.facebook authorize:permissions];
        return YES;
    }
    
    return NO;
}

-(void) logOut{
    [self.facebook logout: self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"FBAccessTokenKey"];
    
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerLoginSucceed
                                                    object:self
                                                  userInfo:nil]];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerLoginFailed
                                                    object:self
                                                  userInfo:nil]];
}

- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt{
    
}

- (void)fbSessionInvalidated{
    
}


- (void)fbDidLogout{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"FBAccessTokenKey"];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerLogOutSucceed
                                                    object:self
                                                  userInfo:nil]];
}

- (void) postToWallWithTitle:(NSString *)title AndMessage:(NSString *)message AndPicture:(NSString *)picture {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Radii", @"name",
                                   @"Check this out", @"caption",
                                   message, @"description",
                                 //  picture, @"picture",
                                   nil];
    
    [[self facebook] dialog:@"feed"
                  andParams:params
                andDelegate:self];
}


- (void) postCheckinWithPlaceID:(NSString *)placeID AndLatitude:(NSNumber *)latitude AndLongitude:(NSNumber *)longitude {
    
    SBJSON *jsonWriter = [SBJSON new];
    NSDictionary *coordinates = [NSDictionary dictionaryWithObjectsAndKeys:
                                 latitude, @"latitude",
                                 longitude, @"longitude",
                                 nil];
    
    NSString *coordinatesStr = [jsonWriter stringWithObject:coordinates];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   placeID, @"place",
                                   coordinatesStr, @"coordinates",
                                   @"", @"message",
                                   nil];
    [self.facebook requestWithGraphPath:@"me/checkins"
                              andParams:params
                          andHttpMethod:@"POST"
                            andDelegate:self];
}

#pragma mark -
#pragma mark FBRequestDelegate

- (void)request:(FBRequest *)request didLoad:(id)result {
    if ([request.url hasSuffix:@"checkins"] ) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerCheckinSucceed
                                                        object:self
                                                      userInfo:nil]];
    } else {
        //TODO: Should check for feed
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerWallPostSucceed
                                                        object:self
                                                      userInfo:nil]];
    }
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error {
    if ([request.url hasSuffix:@"checkins"] ) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerCheckinFailed
                                                        object:self
                                                      userInfo:nil]];
    } else {
        //TODO: Should check for feed
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kFacebookManagerWallPostFailed
                                                                                             object:self
                                                                                           userInfo:nil]];
    }
}

@end
