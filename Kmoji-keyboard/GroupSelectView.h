//
//  GroupSelectView.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/5/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KMEmotionTag;

@protocol GroupSelectViewDelegate <UIScrollViewDelegate>

- (void)didSelectGroup:(KMEmotionTag *)tag;

@end

@interface GroupSelectView : UIScrollView

@property (nonatomic, weak) id<GroupSelectViewDelegate> groupSelectViewDelegate;

- (void)setupWithGroups:(NSArray *)groupArray;
- (void)selectPreviousGroup;
- (void)selectGroupAtIndex:(NSUInteger)index;

@end
