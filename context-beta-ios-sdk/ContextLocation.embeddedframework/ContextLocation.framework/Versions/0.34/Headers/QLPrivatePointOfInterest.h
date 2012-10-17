#import <Foundation/Foundation.h>

@class QLGeoFence;
@class QLLocation;

@interface QLPrivatePointOfInterest : NSObject

@property (nonatomic, assign) NSString *id;
@property (nonatomic, assign) NSUInteger relevanceIndex;
@property (nonatomic, strong) QLLocation *center;
@property (nonatomic, strong) QLGeoFence *geoFence;

@end
