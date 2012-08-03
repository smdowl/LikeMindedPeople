//
//  SideBar.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideBar : UIView
{
	UILabel *_header;
	UITableView *_listView;
}

@property (nonatomic,strong) UITableView *listView;

@end
