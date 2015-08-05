//
//  KMTopBarView.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/8/2.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KMSharingDestination) {
    KMSharingDestination_Wechat = 77,
    KMSharingDestination_WechatTimeline,
    KMSharingDestination_QQ
};

@interface KMTopBarView : UIView

@property (nonatomic, assign) KMSharingDestination shareTo;

@end
