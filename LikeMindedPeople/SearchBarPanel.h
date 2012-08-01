//
//  SearchBarPanel.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchBarPanelDelegate.h"

@class SearchBar;
@interface SearchBarPanel : UIView <UITextFieldDelegate>
{
	__weak id<SearchBarPanelDelegate> _delegate;
	
	NSUInteger _selectedIndex;
	NSArray *_buttonsArray;	
	
	UIButton *_searchButton;
	SearchBar *_searchBar;
	
	UIButton *_barButton;
	UIButton *_cafeButton;
	UIButton *_clubButton;
	UIButton *_foodButton;
	
	NSArray *_searchKeys;
}

@property (nonatomic, weak) IBOutlet id<SearchBarPanelDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *searchButton;
@property (nonatomic, strong) IBOutlet SearchBar *searchBar;

@property (nonatomic, strong) IBOutlet UIButton *barButton;
@property (nonatomic, strong) IBOutlet UIButton *cafeButton;
@property (nonatomic, strong) IBOutlet UIButton *clubButton;
@property (nonatomic, strong) IBOutlet UIButton *foodButton;

- (IBAction)tabBarButtonSelected:(id)sender;

- (void)setup;
- (void)selectButton:(NSUInteger)buttonIndex; // Use -1 for none

@end
