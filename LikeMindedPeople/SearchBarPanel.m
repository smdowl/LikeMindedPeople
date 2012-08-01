//
//  SearchBarPanel.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchBarPanel.h"
#import "SearchBar.h"

#define SEARCH_BUTTON_SIZE 200

@interface SearchBarPanel()

- (void)_animateToFrame:(CGRect)frame;
- (void)_showSearchBar:(BOOL)show;

@end

@implementation SearchBarPanel

@synthesize delegate = _delegate;
@synthesize searchButton = _searchButton;
@synthesize searchBar = _searchBar;
@synthesize barButton = _barButton;
@synthesize cafeButton = _cafeButton;
@synthesize clubButton = _clubButton;
@synthesize foodButton = _foodButton;

#pragma mark -
#pragma mark IBActions

- (IBAction)buttonPressed:(id)sender
{
	UIButton *selectedButton = (UIButton *)sender;
	NSUInteger buttonIndex = [_buttonsArray indexOfObject:selectedButton];
	
	// Disabled is taking the meaning of selected
	if (_selectedIndex != -1)
	{
		UIButton *previousButton = [_buttonsArray objectAtIndex:_selectedIndex];
		previousButton.enabled = YES;
	}
	
	// If the previous button was the search button, hide the text field
	if (_selectedIndex == 0)
	{
		CGRect searchButtonRect = _searchButton.frame;
		searchButtonRect.size.width -= SEARCH_BUTTON_SIZE;
		_searchButton.frame = searchButtonRect;
		
		_searchButton.backgroundColor = [UIColor purpleColor];
		
		[_searchBar animateOut];
		[UIView beginAnimations:nil context:nil];
		for (int i=1; i<[_buttonsArray count]; i++)
		{
			UIButton *button = [_buttonsArray objectAtIndex:i];
			CGRect buttonFrame = [button frame];
			buttonFrame.origin.x -= ([_buttonsArray count] - i)*(SEARCH_BUTTON_SIZE - button.frame.size.width)/(_buttonsArray.count -1);
			button.frame = buttonFrame;
		}
		[UIView commitAnimations];
	}
	
	selectedButton.enabled = NO;
	_selectedIndex = buttonIndex;

	// If this button is the search button, show the text field
	if (_selectedIndex == 0)
	{
		CGRect searchButtonRect = _searchButton.frame;
		searchButtonRect.size.width += SEARCH_BUTTON_SIZE;
		_searchButton.frame = searchButtonRect;
		
		_searchButton.backgroundColor = [UIColor purpleColor];
		
		[_searchBar animateIn:SEARCH_BUTTON_SIZE];
		
		[UIView beginAnimations:nil context:nil];
		for (int i=1; i<[_buttonsArray count]; i++)
		{
			UIButton *button = [_buttonsArray objectAtIndex:i];
			CGRect buttonFrame = [button frame];
			buttonFrame.origin.x += ([_buttonsArray count] - i)*(SEARCH_BUTTON_SIZE - button.frame.size.width)/(_buttonsArray.count -1);
			button.frame = buttonFrame;
		}
		[UIView commitAnimations];
	}
}

#pragma mark -
#pragma mark Initialization

- (void)setup
{
	// Store the buttons in an array for easy index reference
	_buttonsArray = [NSArray arrayWithObjects:_searchButton, _barButton, _cafeButton, _clubButton, _foodButton, nil];
	
	// TODO: One set of these button images should be different. I'm thinking darker for highlighted?
	// When a selected button is selected it has another image
	[_searchButton setImage:[UIImage imageNamed:@"magnifyingactive.png"] forState:UIControlStateHighlighted];
	[_barButton setImage:[UIImage imageNamed:@"barsactive.jpg"] forState:UIControlStateHighlighted];
	[_cafeButton setImage:[UIImage imageNamed:@"cafeactive.jpg"] forState:UIControlStateHighlighted];
	[_clubButton setImage:[UIImage imageNamed:@"clubsactive.jpg"] forState:UIControlStateHighlighted];
	[_foodButton setImage:[UIImage imageNamed:@"foodactive.jpg"] forState:UIControlStateHighlighted];

	[_searchButton setImage:[UIImage imageNamed:@"magnifyingactive.png"] forState:UIControlStateDisabled];
	[_barButton setImage:[UIImage imageNamed:@"barsactive.jpg"] forState:UIControlStateDisabled];
	[_cafeButton setImage:[UIImage imageNamed:@"cafeactive.jpg"] forState:UIControlStateDisabled];
	[_clubButton setImage:[UIImage imageNamed:@"clubsactive.jpg"] forState:UIControlStateDisabled];
	[_foodButton setImage:[UIImage imageNamed:@"foodactive.jpg"] forState:UIControlStateDisabled];
	
	_selectedIndex = -1;
}

#pragma mark -
#pragma mark Animation Methods

- (void)_animateToFrame:(CGRect)frame
{
	self.frame = frame;
}

- (void)_showSearchBar:(BOOL)show
{
	
}

@end
