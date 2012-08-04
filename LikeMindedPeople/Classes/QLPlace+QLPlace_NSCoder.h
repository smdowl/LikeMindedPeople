//
//  QLPlace+QLPlace_NSCoder.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ContextLocation/QLPlace.h>

@interface QLPlace (QLPlace_NSCoder)
- (void)encodeWithCoder:(NSCoder *)aCoder;
@end
