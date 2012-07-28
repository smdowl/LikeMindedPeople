#import <Foundation/Foundation.h>

@class UIViewController;

@interface IRContextImageRecognitionConnector : NSObject

- (void)retrieveTargetBundleAndOnSuccess:(void (^)())success 
                                 failure:(void (^)(NSError *error))failure;

- (void)showImageRecognitionUIFromViewController:(UIViewController *)viewController
                                    fetchTargets:(BOOL)fetchTargets
                                         failure:(void (^)(NSError *error))failure;

@end
