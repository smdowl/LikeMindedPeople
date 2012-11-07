//
//  MenuViewController.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController <UIWebViewDelegate>
{
    // Url provided by foursqaure for the menu
	NSString *_menuURLString;
    
    // We use this webview to contain the url provied by foursquare
	UIWebView *_menuView;
}

@property (nonatomic,strong) NSString *menuURLString;
@property (nonatomic,strong) UIWebView *menuView;

- (IBAction)hideMenu;

@end
