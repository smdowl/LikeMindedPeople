
#import <Foundation/Foundation.h>
#import <Common/QLJsonSerializable.h>

#import "QLGeoFence.h"

@interface QLGeofencePolygon : QLGeoFence <QLJsonSerializable>

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSArray *locations;

@end
