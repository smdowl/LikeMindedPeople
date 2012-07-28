#import <Foundation/Foundation.h>

@interface PRAttributeCategory : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, assign) double likelihood;

-(id)initWithKey:(NSString *)k;

@end
