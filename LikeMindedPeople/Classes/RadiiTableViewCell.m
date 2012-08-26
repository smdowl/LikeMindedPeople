//
//  RadiiTableViewCell.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RadiiTableViewCell.h"

@implementation RadiiTableViewCell
@synthesize nameLabel = _nameLabel;
@synthesize peopleHistoryCountLabel = _peopleHistoryCountLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
