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
	UIWebView *_menuView;
	NSString *_menuURLString;
}

@property (nonatomic,strong) IBOutlet UIWebView *menuView;
@property (nonatomic,strong) NSString *menuURLString;

- (IBAction)hideMenu;

@end
