//
//  UIPureColorButton.h
//  Kmoji-objc
//
//  Created by yangx2 on 11/1/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface UIPureColorButton : UIButton

- (instancetype)initWithBgColor:(UIColor *)bgColor highlightedColor:(UIColor *)hgColor;

@property (nonatomic) IBInspectable UIColor *bgColor;
@property (nonatomic) IBInspectable UIColor *hgColor;
@property (nonatomic) IBInspectable UIColor *sgColor;

@end
