//
//  SearchView.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchView.h"
#import "DetailView.h"

@implementation SearchView
@synthesize searchBarPanel = _searchBarPanel;
@synthesize searchResultsView = _searchResultsView;
@synthesize noResultsView = _noResultsView;
@synthesize detailView = _detailView;

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

- (void)showDetailView
{
	if (!_detailView.isShowing)
	{
		CGRect detailFrame = _detailView.frame;
		detailFrame.origin.x = self.frame.size.width;
		_detailView.frame = detailFrame;
		
		_detailView.hidden = NO;
		[UIView beginAnimations:nil context:nil];
		
		detailFrame = _detailView.frame;
		detailFrame.origin.x -= _detailView.frame.size.width;
		_detailView.frame = detailFrame;
		
		[UIView commitAnimations];	
		
		_detailView.isShowing = YES;
	}
}

- (void)hideDetailView
{	
	if (_detailView.isShowing)
	{
		[UIView animateWithDuration:0.2 
						 animations:^()
		 {
			 CGRect detailFrame = _detailView.frame;
			 detailFrame.origin.x += _detailView.frame.size.width;
			 _detailView.frame = detailFrame;
			 
			 [UIView commitAnimations];	
		 } 
						 completion:^(BOOL finished)
		 {
			 _detailView.hidden = YES;
		 }];	 
		
		[_searchResultsView deselectRowAtIndexPath:[_searchResultsView indexPathForSelectedRow] animated:YES];
		
		_detailView.isShowing = NO;
	}
}

@end
