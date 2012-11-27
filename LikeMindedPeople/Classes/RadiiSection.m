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
        
        [self.layer setShadowOffset:CGSizeMake(0.0, 5.0)];
        [self.layer setShadowOpacity:0.8];
        [self.layer setShadowRadius:2.0];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
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
