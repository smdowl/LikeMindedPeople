#import <Foundation/Foundation.h>

@class UIViewController;


@protocol IRContextImageRecognitionConnectorDelegate <NSObject>

- (void)didAcquireTarget:(NSString *)targetName contentURL:(NSURL *)contentURL;

@end


@interface IRContextImageRecognitionConnector : NSObject

@property (assign) id<IRContextImageRecognitionConnectorDelegate> delegate;

- (void)retrieveTargetBundleAndOnSuccess:(void (^)())success 
                                 failure:(void (^)(NSError *error))failure;

- (void)showImageRecognitionUIFromViewController:(UIViewController *)viewController
                                    fetchTargets:(BOOL)fetchTargets
                                         failure:(void (^)(NSError *error))failure;

@end
