#import <Foundation/Foundation.h>

@class PRProfile;

@protocol PRContextInterestsDelegate <NSObject>

@optional

- (void)interestsDidChange:(PRProfile *)profile;
- (void)interestsPermissionDidChange:(BOOL)interestsPermission;

@end


@interface PRContextInterestsConnector : NSObject

@property (assign) id<PRContextInterestsDelegate> delegate;

@property (nonatomic, readonly) PRProfile *interests;
@property (nonatomic, readonly) BOOL isInterestsEnabled;

@end
