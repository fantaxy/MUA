//
//  KMDownloadedEmotionViewController.h
//  Kmoji-objc
//
//  Created by yangx2 on 12/6/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMEmotionGridView.h"

@interface KMDownloadedEmotionViewController : UIViewController <KMEmotionGridViewDelegate>

@property (nonatomic, strong) NSDictionary *emotionInfo;

@end
