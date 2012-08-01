//
//  SearchBarPanelDelegate.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SearchBarPanelDelegate <NSObject>

- (void)beginSearchForPlaces:(NSString *)searchText;

@end
