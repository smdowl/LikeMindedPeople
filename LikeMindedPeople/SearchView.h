//
//  SearchView.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchViewDelegate.h"

@class SearchBar, SearchBarPanel, DetailView;
@interface SearchView : UIView <UITextFieldDelegate>
{
	__weak id<SearchViewDelegate> _delegate;
	
	NSUInteger _selectedIndex;
	NSArray *_buttonsArray;	
	
	UIButton *_searchButton;
	SearchBar *_searchBar;
	UIView *_searchBarContainerView;
	
	UIView *_searchBarPanel;
	UIButton *_barButton;
	UIButton *_cafeButton;
	UIButton *_clubButton;
	UIButton *_foodButton;
	
	NSArray *_searchKeys;
	
	UITableView *_searchResultsView;
	UIView *_noResultsView;
	
	// A detail view that can be created and animated across
	DetailView *_detailView;
}

@property (nonatomic, weak) IBOutlet id<SearchViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *searchButton;
@property (nonatomic, strong) IBOutlet SearchBar *searchBar;

@property (nonatomic, strong) IBOutlet UIView *searchBarPanel;
@property (nonatomic, strong) IBOutlet UIButton *barButton;
@property (nonatomic, strong) IBOutlet UIButton *cafeButton;
@property (nonatomic, strong) IBOutlet UIButton *clubButton;
@property (nonatomic, strong) IBOutlet UIButton *foodButton;

@property (nonatomic, strong) IBOutlet UITableView *searchResultsView;
@property (nonatomic, strong) IBOutlet UIView *noResultsView;

@property (nonatomic, strong) IBOutlet DetailView *detailView;

- (CGFloat)panelHeight;	// The height of the tab bar or tab bar and search box depending

- (void)selectButton:(NSUInteger)buttonIndex; // Use -1 for none

- (void)setData:(NSArray *)data;

- (void)showDetailView;

- (IBAction)tabBarButtonSelected:(id)sender;
- (IBAction)hideDetailView;
- (IBAction)getDirections;

@end
