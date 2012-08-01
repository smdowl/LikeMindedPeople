//
//  SearchView.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchView.h"

@implementation SearchView
@synthesize searchBarPanel = _searchBarPanel;
@synthesize searchResultsView = _searchResultsView;
@synthesize noResultsView = _noResultsView;

- (void)setData:(NSArray *)data
{
	if ([data count])
	{
		[_noResultsView removeFromSuperview];
	}
	else
	{
		[self insertSubview:_noResultsView aboveSubview:_searchResultsView];
	}
	
	[_searchResultsView reloadData];
}

@end
