
#import <Foundation/Foundation.h>

@class QLGeoFence;
@class QLPlaceAttributes;

@interface QLPlace : NSObject

@property (nonatomic, assign) long long id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) QLGeoFence *geoFence;
@property (nonatomic, strong) QLPlaceAttributes *placeAttributes;

@end
