//
//  UIPureColorButton.m
//  Kmoji-objc
//
//  Created by yangx2 on 11/1/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "UIPureColorButton.h"

@implementation UIPureColorButton
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithBgColor:(UIColor *)bgColor highlightedColor:(UIColor *)hgColor
{
    self = [super init];
    if (self)
    {
        _bgColor = bgColor;
        _hgColor = hgColor;
        [self setBackgroundColor:bgColor];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted)
    {
        self.backgroundColor = _hgColor;
    }
    else
    {
        self.backgroundColor = _bgColor;
    }
}

@end
