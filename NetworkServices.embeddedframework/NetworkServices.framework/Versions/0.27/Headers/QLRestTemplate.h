#import <Foundation/Foundation.h>
#import <Common/QLJsonSerializable.h>

extern NSString * const QLRestTemplateErrorDomain;

@interface QLRestTemplate : NSObject

@property (readonly, nonatomic, strong) NSURL *baseURL;

+ (QLRestTemplate *)clientWithBaseURL:(NSURL *)url;

- (id)initWithBaseURL:(NSURL *)url;

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;
- (void)clearAuthorizationHeader;

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

- (void)get:(NSString *)path
responseType:(Class)responseType
 paramaters:(NSDictionary *)paramaters 
    success:(void (^)(id responseObject))success 
    failure:(void (^)(NSError *error))failure;

- (void)post:(NSString *)path
responseType:(Class)responseType
     payload:(id<QLJsonSerializable>)payload
     success:(void (^)(id responseObject))success 
     failure:(void (^)(NSError *error))failure;

- (void)put:(NSString *)path
    payload:(id<QLJsonSerializable>)payload
    success:(void (^)())success 
    failure:(void (^)(NSError *error))failure;

- (void)delete:(NSString *)path
    paramaters:(NSDictionary *)paramaters 
       success:(void (^)())success 
       failure:(void (^)(NSError *error))failure;

@end

