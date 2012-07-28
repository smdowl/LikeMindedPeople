//
//  NSObject.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (DTRuntime)

+ (void)swizzleMethod:(SEL)selector withMethod:(SEL)otherSelector;

@end