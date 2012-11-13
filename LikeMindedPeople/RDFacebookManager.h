//
//  RDFacebookManager.h
//  LikeMindedPeople
//
//  Created by Lucas Coelho on 11/13/12.
//
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

#define FACEBOOK_MANAGER [RDFacebookManager sharedRDFacebookManager]

extern NSString * const kFacebookManagerLoginSucceed;
extern NSString * const kFacebookManagerLoginFailed;
extern NSString * const kFacebookManagerCheckinSucceed;
extern NSString * const kFacebookManagerCheckinFailed;
extern NSString * const kFacebookManagerWallPostSucceed;
extern NSString * const kFacebookManagerWallPostFailed;
extern NSString * const kFacebookManagerLogOutSucceed;

@interface RDFacebookManager : NSObject <FBRequestDelegate,FBSessionDelegate,FBDialogDelegate>

{
    Facebook            *_facebook;
}

+ (RDFacebookManager *)sharedRDFacebookManager;

@property (nonatomic, retain) Facebook    *facebook;
- (BOOL) loginToFacebookIfNeeded;
- (void) logOut;
- (void) postToWallWithTitle:(NSString *)title AndMessage:(NSString *)message AndPicture:(NSString *)picture;
- (void) postCheckinWithPlaceID:(NSString *)placeID AndLatitude:(NSNumber *)latitude AndLongitude:(NSNumber *)longitude;

@end
