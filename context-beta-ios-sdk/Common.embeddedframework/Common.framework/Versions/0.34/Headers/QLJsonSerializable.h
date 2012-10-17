
#import <Foundation/Foundation.h>

@protocol QLJsonSerializable <NSObject>

@optional

- (id)initWithAttributes:(id)attributes error:(NSError **) error;
- (id)initWithAttributes:(id)attributes;

- (id)attributes;

@end
