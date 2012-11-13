//
//  SearchView.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchView.h"
#import "SearchBar.h"
#import "DetailView.h"
#import "LocationDetailsDTO.h"

@interface SearchView (PrivateUtilities)
- (void)_showSearchBar;
- (void)_hideSearchBar;

- (void)_barSwiped:(UISwipeGestureRecognizer *)recognizer;

@end

@implementation SearchView
@synthesize delegate = _delegate;

@synthesize searchButton = _searchButton;
@synthesize searchBar = _searchBar;

@synthesize searchBarPanel = _searchBarPanel;
@synthesize barButton = _barButton;
@synthesize cafeButton = _cafeButton;
@synthesize clubButton = _clubButton;
@synthesize foodButton = _foodButton;

@synthesize searchResultsView = _searchResultsView;
@synthesize noResultsView = _noResultsView;

- (void)awakeFromNib
{
	// Store the buttons in an array for easy index reference
	_buttonsArray = [NSArray arrayWithObjects:_searchButton, _barButton, _cafeButton, _clubButton, _foodButton, nil];
	
	// When a selected button is selected it has another image
	[_searchButton setImage:[UIImage imageNamed:@"searchbtn.png"] forState:UIControlStateNormal];
	[_barButton setBackgroundImage:[UIImage imageNamed:@"barsbtn.png"] forState:UIControlStateNormal];
	[_cafeButton setImage:[UIImage imageNamed:@"cafebtn.png"] forState:UIControlStateNormal];
	[_clubButton setImage:[UIImage imageNamed:@"clubsbtn.png"] forState:UIControlStateNormal];
	[_foodButton setImage:[UIImage imageNamed:@"foodbtn.png"] forState:UIControlStateNormal];
	
	[_searchButton setImage:[UIImage imageNamed:@"searchbtn2.png"] forState:UIControlStateHighlighted];
	[_barButton setImage:[UIImage imageNamed:@"barsbtn2.png"] forState:UIControlStateHighlighted];
	[_cafeButton setImage:[UIImage imageNamed:@"cafebtn2.png"] forState:UIControlStateHighlighted];
	[_clubButton setImage:[UIImage imageNamed:@"clubsbtn2.png"] forState:UIControlStateHighlighted];
	[_foodButton setImage:[UIImage imageNamed:@"foodbtn2.png"] forState:UIControlStateHighlighted];
	
	[_searchButton setImage:[UIImage imageNamed:@"searchbtn3.png"] forState:UIControlStateSelected];
	[_barButton setImage:[UIImage imageNamed:@"barsbtn3.png"] forState:UIControlStateSelected];
	[_cafeButton setImage:[UIImage imageNamed:@"cafebtn3.png"] forState:UIControlStateSelected];
	[_clubButton setImage:[UIImage imageNamed:@"clubsbtn3.png"] forState:UIControlStateSelected];
	[_foodButton setImage:[UIImage imageNamed:@"foodbtn3.png"] forState:UIControlStateSelected];
	
	_searchKeys = [NSArray arrayWithObjects:@"", @"bar", @"cafe", @"nightclub", @"food", nil];
		
	_selectedIndex = -1;
	
	_searchResultsView.rowHeight = 35.0;
    
    // Must add two recognizer to each button because the direction property only corresponds to what will tigger an event, not the direction that was actually swiped
    for (UIButton *button in _buttonsArray)
	{
		UISwipeGestureRecognizer *upRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_barSwiped:)];
        upRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
		[button addGestureRecognizer:upRecognizer];
        
        UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_barSwiped:)];
        downRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
		[button addGestureRecognizer:downRecognizer];
	}
}		

#pragma mark -
#pragma mark External Methods
 -(CGFloat)panelHeight
{
    // Previously also included the search bar if it had been added (ie someone was searching) this was causing a UI glitch in another case and I can't remember what the advantage of it was.
//	return _searchBar ? _searchBar.frame.size.height + _searchBarPanel.frame.size.height : _searchBarPanel.frame.size.height;
    
    return _searchBarPanel.frame.size.height;
}

- (void)selectButton:(NSUInteger)buttonIndex
{		
	// Deselect the previous button unless its the same button again
	if (_selectedIndex != -1 && _selectedIndex != buttonIndex)
	{
		UIButton *previousButton = [_buttonsArray objectAtIndex:_selectedIndex];
		previousButton.selected = NO;
		
		[_delegate clearResults];
	}
	
	// If the previous button was the search button, hide search box
	if (_selectedIndex == 0)
	{
		[self _hideSearchBar];
		_searchButton.selected = NO;
		
		if (buttonIndex == 0)
		{
			_selectedIndex = -1;
			return;
		}
	}
	
	// Clear the string that was previoiusly searched for so it doesn't appear in the search box
	_previousSearch = nil;
	
	// Update the selected index
	_selectedIndex = buttonIndex;
	
	if (_selectedIndex != -1)
	{
		UIButton *selectedButton = [_buttonsArray objectAtIndex:_selectedIndex];
		
		selectedButton.selected = YES;
		
		// If this button is the search button, show the text field
		if (_selectedIndex == 0)
			[self _showSearchBar];
		
		// Don't want to search if the search was selected until the keyboard return is pressed
		if (_selectedIndex != 0)
		{
			NSString *searchKey = [_searchKeys objectAtIndex:_selectedIndex];
			[_delegate beginSearchForPlacesWithName:nil type:searchKey];
		}
	}
}

- (void)setData:(NSArray *)data
{
	if ([data count])
	{
		//		[_noResultsView removeFromSuperview];
		_noResultsView.hidden = YES;
	}
	else
	{
		//		[self insertSubview:_noResultsView aboveSubview:_searchResultsView];
		_noResultsView.hidden = NO;
	}
	
	[_searchResultsView reloadData];
}

//- (void)setFrame:(CGRect)frame
//{
//    super.frame = frame;
//    
//    CGRect searchResultsFrame = _searchResultsView.frame;
//    searchResultsFrame.size.height = frame.size.height - _searchBarPanel.frame.size.height;
//    _searchResultsView.frame = searchResultsFrame;
////    _noResultsView.superview.frame = searchResultsFrame;
//    _noResultsView.frame = searchResultsFrame;
//    
//}

#pragma mark -
#pragma mark IBActions

- (IBAction)cancelSearch:(id)sender
{
	[_delegate cancelSearch];
	_previousSearch = nil;
}

- (IBAction)tabBarButtonSelected:(id)sender
{
	NSUInteger buttonIndex = [_buttonsArray indexOfObject:sender];
	
	[self selectButton:buttonIndex];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString *searchText = textField.text;
	[_delegate beginSearchForPlacesWithName:searchText type:nil];
	_previousSearch = searchText;
    [self _hideSearchBar];
	[textField resignFirstResponder];
	
	return YES;
}

@end

@implementation SearchView (PrivateUtilities)

- (void)_showSearchBar
{
	// Load and set up the search bar into the _searchBar variable
	[[NSBundle mainBundle] loadNibNamed:@"SearchBar" owner:self options:nil];
	
	_searchBar.searchBox.delegate = self;
	if (_previousSearch)
		_searchBar.searchBox.text = _previousSearch;
		
	// Make the SearchView larger and add a UIView in the extra space which clips to its bounds then animate the bar in
	CGRect searchViewFrame = self.frame;
	searchViewFrame.origin.y += _searchBar.frame.size.height;
	searchViewFrame.size.height += _searchBar.frame.size.height;
	self.frame = searchViewFrame;
	
	_searchBarContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width,_searchBar.frame.size.height)];
	_searchBarContainerView.clipsToBounds = YES;
	[self addSubview:_searchBarContainerView];
	
	CGRect searchBarFrame = _searchBar.frame;
	searchBarFrame.origin.y += _searchBar.frame.size.height;
	_searchBar.frame = searchBarFrame;
    
	CGRect searchBarPanelFrame = _searchBarPanel.frame;
	searchBarPanelFrame.origin.y += _searchBar.frame.size.height;
	_searchBarPanel.frame = searchBarPanelFrame;
	
	[_searchBarContainerView addSubview:_searchBar];
	
	[UIView beginAnimations:nil context:nil];
	
	searchBarFrame.origin.y -= _searchBar.frame.size.height;
	_searchBar.frame = searchBarFrame;
	
	[UIView commitAnimations];
	
	[_searchBar becomeFirstResponder];
}

- (void)_hideSearchBar
{				
	[UIView animateWithDuration:0.2 animations:^()
	 {
		 CGRect searchViewFrame = self.frame;
		 searchViewFrame.origin.y -= _searchBar.frame.size.height;
		 searchViewFrame.size.height -= _searchBar.frame.size.height;
		 self.frame = searchViewFrame;
		 
		 CGRect containerFrame = _searchBarContainerView.frame;
		 containerFrame.origin.y -= _searchBarContainerView.frame.size.height;
		 _searchBarContainerView.frame = containerFrame;
		 
		 CGRect searchBarFrame = _searchBar.frame;
		 searchBarFrame.origin.y += _searchBar.frame.size.height;
		 _searchBar.frame = searchBarFrame;
         
         CGRect searchBarPanelFrame = _searchBarPanel.frame;
         searchBarPanelFrame.origin.y -= _searchBar.frame.size.height;
         _searchBarPanel.frame = searchBarPanelFrame;
         
	 } 
					 completion:^(BOOL finished)
	 {	
		 [_searchBar removeFromSuperview];
		 _searchBar = nil;
		 
		 [_searchBarContainerView removeFromSuperview];
		 _searchBarContainerView = nil;
		 
	 }];
	

}

- (void)_barSwiped:(UISwipeGestureRecognizer *)recognizer
{
    [_delegate slideView:recognizer.direction == UISwipeGestureRecognizerDirectionUp];
}

@end
