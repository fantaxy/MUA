//
//  KMDownloadedEmotionViewController.h
//  Kmoji-objc
//
//  Created by yangx2 on 12/6/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMEmotionGridView.h"

@class KMEmotionTag;

@interface KMDownloadedEmotionViewController : UIViewController <KMEmotionGridViewDelegate>

@property (nonatomic, strong) KMEmotionTag *emotionTag;

@end
