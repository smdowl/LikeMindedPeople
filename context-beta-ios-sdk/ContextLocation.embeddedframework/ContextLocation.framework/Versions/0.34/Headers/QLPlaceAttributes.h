#import <Foundation/Foundation.h>

@interface QLPlaceAttributes : NSObject

- (id)initWithPlaceAttributes:(NSDictionary *)placeAttributes;
- (NSArray *)allKeys;
- (NSString *)valueForKey:(NSString *)key;

@end
