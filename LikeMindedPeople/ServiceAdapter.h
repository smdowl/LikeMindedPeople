//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>

@interface ServiceAdapter : NSObject {
    NSMutableData *responseData;
}


+ (void)getAllUsersWithSuccess:(void (^)(id))success;

+ (void)callServiceWithPath:(NSString *)path
                 httpMethod:(NSString *)method
            dataObj:(id)dataObj
            success:(void (^)(id))success;
@end
