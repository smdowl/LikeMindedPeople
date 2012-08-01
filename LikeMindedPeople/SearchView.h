//
//  SearchView.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchBarPanel;
@interface SearchView : UIView
{
	SearchBarPanel *_searchBarPanel;
	
	UITableView *_searchResultsView;
	UIView *_noResultsView;
}

@property (nonatomic, strong) IBOutlet SearchBarPanel *searchBarPanel;

@property (nonatomic, strong) IBOutlet UITableView *searchResultsView;
@property (nonatomic, strong) IBOutlet UIView *noResultsView;

@end
