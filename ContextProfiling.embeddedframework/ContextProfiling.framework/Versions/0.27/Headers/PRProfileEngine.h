#import <Foundation/Foundation.h>

@class PRProfile;

@interface PRProfileEngine : NSObject

@property (nonatomic, strong) NSString *rulesFile;
@property (nonatomic, readonly) PRProfile *profile;

@end
