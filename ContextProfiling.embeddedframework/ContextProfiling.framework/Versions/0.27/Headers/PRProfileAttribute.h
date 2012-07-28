#import <Foundation/Foundation.h>

@class PRAttributeCategory;

@interface PRProfileAttribute : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *attributeCategories;

-(id)initWithKey:(NSString *)k;
-(void)addCategory:(PRAttributeCategory *) category;

@end
