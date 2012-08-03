//
//  SideBar.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SideBar.h"

#define HEADER_HEIGHT 40.0

@implementation SideBar
@synthesize listView = _listView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
		
		CGRect headerFrame = CGRectMake(0,0,self.bounds.size.width, HEADER_HEIGHT);
		_header = [[UILabel alloc] initWithFrame:headerFrame];
		_header.textAlignment = UITextAlignmentCenter;
		_header.text = @"Settings";
		_header.backgroundColor = [UIColor clearColor];
		[self addSubview:_header];
		
		CGRect listViewFrame = self.bounds;
		listViewFrame.origin.y += HEADER_HEIGHT;
		listViewFrame.size.height -= HEADER_HEIGHT;
		_listView = [[UITableView alloc] initWithFrame:listViewFrame];
		_listView.backgroundColor = [UIColor clearColor];
		[self addSubview:_listView];
    }
    return self;
}

@end
