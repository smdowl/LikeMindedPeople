//
//  SearchBar.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchBar.h"

@implementation SearchBar
@synthesize searchBox = _searchBox;
@synthesize cancelButton = _cancelButton;

//- (void)animateIn
//{
//	CGRect barViewFrame = _barView.frame;
//	barViewFrame.origin.y += _barView.frame.size.height;
//	_barView.frame = barViewFrame;
//	
//	[UIView animateWithDuration:0.25
//					 animations:^
//	 {		 
//		 _barView.hidden = NO;
//		 CGRect newBarViewFrame = _barView.frame;
//		 newBarViewFrame.origin.y -= _barView.frame.size.height;
//		 _barView.frame = newBarViewFrame;	 
//	 }
//					 completion:^(BOOL finished) 
//	 {
//		 
//	 }];
//}
//
//- (void)animateOut
//{		
//	[UIView animateWithDuration:0.25
//					 animations:^
//	 {		 
//		 CGRect newBarViewFrame = _barView.frame;
//		 newBarViewFrame.origin.y += _barView.frame.size.height;
//		 _barView.frame = newBarViewFrame;	 
//	 }
//					 completion:^(BOOL finished) 
//	 {
//		 _barView.hidden = YES;
//		 
//		 CGRect barViewFrame = _barView.frame;
//		 barViewFrame.origin.y -= _barView.frame.size.height;
//		 _barView.frame = barViewFrame;
//	 }];
//}

#pragma mark -
#pragma mark First Responder Chain Methods

- (BOOL)resignFirstResponder
{
	[_searchBox resignFirstResponder];
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[_searchBox becomeFirstResponder];
	return YES;
}


@end
