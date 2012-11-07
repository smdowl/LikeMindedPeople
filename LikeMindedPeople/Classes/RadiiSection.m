//
//  RadiiSection.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 27/10/2012.
//
//

#import "RadiiSection.h"
#import <QuartzCore/QuartzCore.h>

@interface RadiiSection(PrivateUtilities)
- (void)_roundCorners;
@end

@implementation RadiiSection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _roundCorners];
    }
    return self;
}

- (void)awakeFromNib
{
    [self _roundCorners];
}

@end

@implementation RadiiSection(PrivateUtilities)

- (void)_roundCorners
{
    self.layer.cornerRadius = 10.0;
    self.layer.masksToBounds = YES;
}

@end
