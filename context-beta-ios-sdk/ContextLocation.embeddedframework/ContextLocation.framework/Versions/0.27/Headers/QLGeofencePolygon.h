
#import <Foundation/Foundation.h>
#import <Common/QLJsonSerializable.h>

@interface QLGeofencePolygon : NSObject <QLJsonSerializable>

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSArray *locations;

@end
