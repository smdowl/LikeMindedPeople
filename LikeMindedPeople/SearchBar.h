//
//  SearchBar.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchBar : UIView
{
	UITextField *_searchBox;
	UIButton *_cancelButton;
}

@property (nonatomic, strong) IBOutlet UITextField *searchBox;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;

@end
