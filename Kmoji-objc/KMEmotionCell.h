//
//  KMEmotionCell.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/12/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KMEmotionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *emotionName;
@property (weak, nonatomic) IBOutlet UILabel *shortDecription;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UILabel *checkmark;

@end
