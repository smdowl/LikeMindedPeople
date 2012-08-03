//
//  SearchView.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchBarPanel, DetailView;
@interface SearchView : UIView
{
	SearchBarPanel *_searchBarPanel;
	
	UITableView *_searchResultsView;
	UIView *_noResultsView;
	
	// A detail view that can be created and animated across
	DetailView *_detailView;
}

@property (nonatomic, strong) IBOutlet SearchBarPanel *searchBarPanel;

@property (nonatomic, strong) IBOutlet UITableView *searchResultsView;
@property (nonatomic, strong) IBOutlet UIView *noResultsView;

@property (nonatomic, strong) IBOutlet DetailView *detailView;

- (void)setData:(NSArray *)data;
- (void)showDetailView;

@end
