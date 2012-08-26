//
//  RadiiTableViewCell.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadiiTableViewCell : UITableViewCell
{
	UILabel *_nameLabel;
	UILabel *_peopleHistoryCountLabel;
}

@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *peopleHistoryCountLabel;
@end
