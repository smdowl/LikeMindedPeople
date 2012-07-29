//
//  ServiceAdapter.m
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import "ServiceAdapter.h"
#import "AFJSONRequestOperation.h"


@implementation ServiceAdapter


+ (void)getAllUsersWithSuccess:(void (^)(id))success
{
        
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [ServiceAdapter callServiceWithPath:@"users.json" httpMethod:@"GET" dataObj:d success:success];
}


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

+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success
{
	success(nil);
}

+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success
{
	// array of QLPlace
	success(nil);
}

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location success:(void (^)(NSArray *))success
{
	success(nil);
}

@end
