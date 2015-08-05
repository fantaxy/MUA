//
//  KMEmotionView.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/9/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KMEmotionTag;

@protocol KMEmotionViewDelegate <NSObject>

- (void)didSendEmotionWithImagePath:(NSString *)path;

@end

@interface KMEmotionView : UIView

@property (nonatomic, weak) id<KMEmotionViewDelegate> delegate;

- (void)setupEmotionsWithGroup:(KMEmotionTag *)tag;
- (void)setupEmotionsForFavorite;
- (void)scrollToPreviousPage;

@end
