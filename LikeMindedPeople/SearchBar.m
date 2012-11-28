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
