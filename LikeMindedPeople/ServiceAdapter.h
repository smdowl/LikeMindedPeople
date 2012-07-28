//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>

@interface ServiceAdapter : NSObject

+ (void)callService:(NSString *)service
               path:(NSString *)path
            jsonObj:(id)jsonObj
            success:(void (^)(id))success;

@end
