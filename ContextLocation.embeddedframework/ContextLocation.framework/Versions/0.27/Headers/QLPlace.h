
#import <Foundation/Foundation.h>

@class QLGeoFence;

@interface QLPlace : NSObject

@property (nonatomic, assign) long long id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) QLGeoFence *geoFence;

@end
