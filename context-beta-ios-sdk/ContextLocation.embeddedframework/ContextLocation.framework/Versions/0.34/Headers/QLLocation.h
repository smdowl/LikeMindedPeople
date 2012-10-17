#import <Foundation/Foundation.h>
#import <Common/QLJsonSerializable.h>

@interface QLLocation : NSObject <QLJsonSerializable>

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;

- (id)initWithLatitude:(double)latitude andLongitude:(double)longitude;

@end
