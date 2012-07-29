//
//  ServiceAdapter.m
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import "ServiceAdapter.h"
#import "AFJSONRequestOperation.h"
#import <ContextLocation/QLPlace.h>
#import <ContextLocation/QLGeofenceCircle.h>


@implementation ServiceAdapter

+ (void)callServiceWithPath:(NSString *)path
                 httpMethod:(NSString *)method
            dataObj:(id)dataObj
            success:(void (^)(id))success
{

    // Create JSON string
    NSError* error = nil;
    id json = [NSJSONSerialization dataWithJSONObject:dataObj
                                              options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"SeviceAdapter.callService: error encoding JSON: %@", error);
        return;
    }
    
    // Construct URL
    NSArray *urlComponentArray = [[NSArray alloc] initWithObjects:@"http://3j4s.localtunnel.com", @"/", path, nil];
    NSURL *url = [NSURL URLWithString:[urlComponentArray componentsJoinedByString:@""]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Construct post data
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"POST"]) {

        NSString *dataStr = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    
        // Do URL encoding
        // see: http://stackoverflow.com/questions/6822473/correct-bridging-for-arc for ARC/bridge handling
        // http://www.raywenderlich.com/5773/beginning-arc-in-ios-5-tutorial-part-2
        NSString *encodedStr = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                     NULL,
                                                                                     (__bridge CFStringRef)dataStr,
                                                                                     NULL,
                                                                                     CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    
        // Set the HTTP Body
        [request setHTTPBody:[encodedStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSLog(@"ServiceAdapter.callService: Making request=%@", request);
    
    // Make request to server    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"ServiceAdapter.callService: Received type=%@, response=%@", [JSON class], JSON);
        success(JSON);
    } failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
        NSString *errorMsg = [NSString stringWithFormat:@"ServiceAdapter.callService error: %@", error];
        NSLog(@"%@",errorMsg);
        //[errFuncs callWithErrorCode:@"DefaultError" errorMessage:errorMsg];
    }];
    [operation start];
    
}

// Just used for testing
+ (void)getAllUsersWithSuccess:(void (^)(id))success
{
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [ServiceAdapter callServiceWithPath:@"users.json" httpMethod:@"GET" dataObj:d success:success];
}



+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:userId forKey:@"uid"];
    [d setObject:profile forKey:@"profile"];

    // TODO: Uncomment when servers are ready
    //[ServiceAdapter callServiceWithPath:@"/user/upload_profile" httpMethod:@"POST" dataObj:d success:success];

	success(nil);
}

// pointsOfInterest: array of QLPlace
+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success
{
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:userId forKey:@"uid"];
    [d setObject:pointsOfInterest forKey:@"interest"];
    
    //[ServiceAdapter callServiceWithPath:@"/user/uploadPointsOfInterest" httpMethod:@"POST" dataObj:d success:success];
    
	success(nil);
}

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location success:(void (^)(NSArray *))success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [d setObject:userId forKey:@"uid"];
    [d setObject:location forKey:@"location"];
    
	NSMutableArray *places = [NSMutableArray array];
	QLPlace *place = [[QLPlace alloc] init];
	QLGeoFenceCircle *circle = [[QLGeoFenceCircle alloc] init];
	circle.longitude = 37.776074;
	circle.latitude = -122.394304;
	circle.radius = 50;
	place.geoFence = circle;
	place.name = @"tempLocation";
	[places addObject:place];
	
    // TODO: Uncomment when servers come online
    //[ServiceAdapter callServiceWithPath:@"/user/geofences" httpMethod:@"GET" dataObj:d success:success];
    
	success(places);
}

@end
