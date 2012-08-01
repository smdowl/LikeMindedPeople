//
//  SearchBar.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchBar.h"
#define PADDING_WIDTH 20

@implementation SearchBar
@synthesize searchBox = _searchBox;
@synthesize cancelButton = _cancelButton;
@synthesize boxImage = _boxImage;

- (IBAction)cancelSearch:(id)sender
{
	_searchBox.text = @"";
	[_searchBox resignFirstResponder];
}

- (void)animateIn:(CGFloat)width
{
	[UIView animateWithDuration:0.25
					 animations:^
	 {
		 self.hidden = NO;
		 
		 CGRect barFrame = self.frame;
		 barFrame.size.width = width - PADDING_WIDTH - barFrame.origin.x;
		 self.frame = barFrame;
		 
		 CGRect boxFrame = _searchBox.frame;
		 boxFrame.size.width = barFrame.size.width - PADDING_WIDTH - boxFrame.origin.x;
		 _searchBox.frame = boxFrame;
		 
		 CGRect buttonFrame = _cancelButton.frame;
		 buttonFrame.origin.x = boxFrame.origin.x + boxFrame.size.width;
		 _cancelButton.frame = buttonFrame;
		 
		 CGRect boxImageFrame = _boxImage.frame;
		 boxImageFrame.size.width = boxFrame.size.width + buttonFrame.size.width;
		 _boxImage.frame = boxImageFrame;
	 }
					 completion:^(BOOL finished) 
	 {
		 
	 }];
}

- (void)animateOut
{
	// I think just making it disappear is better than having is shink down
	self.hidden = YES;
	[UIView animateWithDuration:0.25
					 animations:^
	 {		 
		 CGRect barFrame = self.frame;
		 barFrame.size.width = 0;
		 self.frame = barFrame;
		 
		 CGRect boxFrame = _searchBox.frame;
		 boxFrame.size.width = 0;
		 _searchBox.frame = boxFrame;
		 [_searchBox resignFirstResponder];
		 
		 CGRect boxImageFrame = _boxImage.frame;
		 boxImageFrame.size.width = 0;
		 _boxImage.frame = boxImageFrame;
		 
		 _cancelButton.alpha = 0;
		 CGRect buttonFrame = _cancelButton.frame;
		 buttonFrame.origin.x = boxFrame.size.width;
	 }
					 completion:^(BOOL finished) 
	 {
		 		 self.hidden = YES;
	 }];
}

- (BOOL)resignFirstResponder
{
	[_searchBox resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	
}

@end
