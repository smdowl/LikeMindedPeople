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

+ (void)callService:(NSString *)service
               path:(NSString *)path
            jsonObj:(id)jsonObj
            success:(void (^)(id))success
{
    // TODO: add app version,
    NSError* error = nil;
    id json = [NSJSONSerialization dataWithJSONObject:jsonObj
                                              options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"SeviceAdapter.callService: error encoding JSON: %@", error);
        return;
    }
    
    NSArray *urlComponentArray = [[NSArray alloc] initWithObjects:@"https://", service, @"local.usablelogin.net/", path, nil];
    
    NSURL *url = [NSURL URLWithString:[urlComponentArray componentsJoinedByString:@""]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    NSString *dataStr = [NSString stringWithFormat:@"json=%@",[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    // see: http://stackoverflow.com/questions/6822473/correct-bridging-for-arc for ARC/bridge handling
    // http://www.raywenderlich.com/5773/beginning-arc-in-ios-5-tutorial-part-2
    NSString *encodedStr = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                     NULL,
                                                                                     (__bridge CFStringRef)dataStr,
                                                                                     NULL,
                                                                                     CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    [request setHTTPBody:[encodedStr dataUsingEncoding:NSUTF8StringEncoding]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        //NSLog(@"ServiceAdapter.callService response: %@", JSON);
        NSString *errorCode = [JSON objectForKey:@"error_code"];
        if (errorCode) {
            //NSString *errorMessage = [JSON objectForKey:@"error_desc"];
        } else {
            success(JSON);
        }
    } failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
        NSString *errorMsg = [NSString stringWithFormat:@"ServiceAdapter.callService error: %@", error];
        NSLog(@"%@",errorMsg);
        //[errFuncs callWithErrorCode:@"DefaultError" errorMessage:errorMsg];
    }];
    [operation start];
    
}

@end
