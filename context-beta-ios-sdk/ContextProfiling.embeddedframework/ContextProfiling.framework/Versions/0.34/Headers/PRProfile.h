#import <Foundation/Foundation.h>

@class PRProfileAttribute;

@interface PRProfile : NSObject

@property (nonatomic, strong) NSDate *creationTime;
@property (nonatomic, strong) NSDictionary *attrs;

-(PRProfileAttribute *)getAttribute:(NSString *)key;
-(void)addAttribute:(PRProfileAttribute *) attribute;

@end
