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

@interface SearchView (PrivateUtilities)
- (void)_showSearchBar;
- (void)_hideSearchBar;
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

@synthesize detailView = _detailView;

- (void)awakeFromNib
{
	// Store the buttons in an array for easy index reference
	_buttonsArray = [NSArray arrayWithObjects:_searchButton, _barButton, _cafeButton, _clubButton, _foodButton, nil];
	
	// TODO: One set of these button images should be different. I'm thinking darker for highlighted?
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
	
	[_searchButton setImage:[UIImage imageNamed:@"searchbtn3.png"] forState:UIControlStateDisabled];
	[_barButton setImage:[UIImage imageNamed:@"barsbtn3.png"] forState:UIControlStateDisabled];
	[_cafeButton setImage:[UIImage imageNamed:@"cafebtn3.png"] forState:UIControlStateDisabled];
	[_clubButton setImage:[UIImage imageNamed:@"clubsbtn3.png"] forState:UIControlStateDisabled];
	[_foodButton setImage:[UIImage imageNamed:@"foodbtn3.png"] forState:UIControlStateDisabled];
	
	_searchKeys = [NSArray arrayWithObjects:@"", @"bar", @"cafe", @"nightclub", @"food", nil];
		
	_selectedIndex = -1;
	
	_searchResultsView.rowHeight = 35.0;
}

#pragma mark -
#pragma mark External Methods
 -(CGFloat)panelHeight
{
	return _searchBar ? _searchBar.frame.size.height + _searchBarPanel.frame.size.height : _searchBarPanel.frame.size.height;
	
}

- (void)selectButton:(NSUInteger)buttonIndex
{	
	// Disabled is taking the meaning of selected
	if (_selectedIndex != -1)
	{
		UIButton *previousButton = [_buttonsArray objectAtIndex:_selectedIndex];
		previousButton.enabled = YES;
	}
	
	// If the previous button was the search button, hide search box
	if (_selectedIndex == 0)
		[self _hideSearchBar];
	
	// Update the selected index
	_selectedIndex = buttonIndex;
	
	if (_selectedIndex != -1)
	{
		UIButton *selectedButton = [_buttonsArray objectAtIndex:_selectedIndex];
		
		selectedButton.enabled = NO;
		
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


- (void)showDetailView
{
	if (!_detailView.isShowing)
	{
		[[NSBundle mainBundle] loadNibNamed:@"DetailView" owner:self options:nil];
		
		CGRect detailFrame = _detailView.frame;
		detailFrame.origin.x = self.frame.size.width;
		_detailView.frame = detailFrame;
		_detailView.hidden = NO;
		[self addSubview:_detailView];
		
//		[UIView beginAnimations:nil context:nil];
		
		[UIView animateWithDuration:0.2
						 animations:^()
		 {
			 
			 CGRect detailFrame = _detailView.frame;
			 detailFrame.origin.x -= _detailView.frame.size.width;
			 _detailView.frame = detailFrame;
			 
			 _searchBarPanel.alpha = 0.0;
			 //		[UIView commitAnimations];	
		 } 
						 completion:^(BOOL finished)
		 {
			 _detailView.isShowing = YES;		 
		 }];
	
	}
}

- (IBAction)hideDetailView
{	
	if (_detailView.isShowing)
	{
		[UIView animateWithDuration:0.2 
						 animations:^()
		 {
			 CGRect detailFrame = _detailView.frame;
			 detailFrame.origin.x += _detailView.frame.size.width;
			 _detailView.frame = detailFrame;
			 
			 _searchBarPanel.alpha = 0.8;
			 
			 [UIView commitAnimations];	
		 } 
						 completion:^(BOOL finished)
		 {
			 _detailView.hidden = YES;
			 _detailView.isShowing = NO;
		 }];	 
		
		[_searchResultsView deselectRowAtIndexPath:[_searchResultsView indexPathForSelectedRow] animated:YES];
		
		
		[_delegate deselectPin];
	}
}

#pragma mark -
#pragma mark IBActions

- (IBAction)tabBarButtonSelected:(id)sender
{
	NSUInteger buttonIndex = [_buttonsArray indexOfObject:sender];
	
	[self selectButton:buttonIndex];
}

- (IBAction)getDirections
{
	[_delegate getDirectionsToLocation:_detailView.data];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString *searchText = textField.text;
	[_delegate beginSearchForPlacesWithName:searchText type:nil];
	
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
	
	[_searchBar.cancelButton addTarget:_delegate action:@selector(cancelSearch) forControlEvents:UIControlEventTouchUpInside];
	
	// Make the SearchView larger and add a UIView in the extra space which clips to its bounds then animate the bar in
	CGRect searchViewFrame = self.frame;
	searchViewFrame.origin.y -= _searchBar.frame.size.height;
	searchViewFrame.size.height += _searchBar.frame.size.height;
	self.frame = searchViewFrame;
	
	_searchBarContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width,_searchBar.frame.size.height)];
	_searchBarContainerView.clipsToBounds = YES;
	[self addSubview:_searchBarContainerView];
	
	CGRect searchBarFrame = _searchBar.frame;
	searchBarFrame.origin.y += _searchBar.frame.size.height;
	_searchBar.frame = searchBarFrame;
	
	[_searchBarContainerView addSubview:_searchBar];
	
	[_delegate checkLayout];
	
	[UIView beginAnimations:nil context:nil];
	
	searchBarFrame.origin.y -= _searchBar.frame.size.height;
	_searchBar.frame = searchBarFrame;
	
	[UIView commitAnimations];
}

- (void)_hideSearchBar
{			
	
	[UIView animateWithDuration:0.2 animations:^()
	 {
		 CGRect searchViewFrame = self.frame;
		 searchViewFrame.origin.y += _searchBar.frame.size.height;
		 searchViewFrame.size.height -= _searchBar.frame.size.height;
		 self.frame = searchViewFrame;
		 
		 [_delegate checkLayout];
		 
		 CGRect containerFrame = _searchBarContainerView.frame;
		 containerFrame.origin.y -= _searchBarContainerView.frame.size.height;
		 _searchBarContainerView.frame = containerFrame;
		 
		 CGRect searchBarFrame = _searchBar.frame;
		 searchBarFrame.origin.y += _searchBar.frame.size.height;
		 _searchBar.frame = searchBarFrame;
	 } 
					 completion:^(BOOL finished)
	 {	
		 [_searchBar removeFromSuperview];
		 _searchBar = nil;
		 
		 [_searchBarContainerView removeFromSuperview];
		 _searchBarContainerView = nil;
		 
	 }];
	

}

@end
