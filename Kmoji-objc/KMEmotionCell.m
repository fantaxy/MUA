//
//  KMEmotionCell.m
//  Kmoji-objc
//
//  Created by yangx2 on 10/12/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionCell.h"

@implementation KMEmotionCell

- (void)awakeFromNib {
    // Initialization code
    self.downloadButton.layer.cornerRadius = 4.f;
    self.checkmark.layer.cornerRadius = 4.f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
