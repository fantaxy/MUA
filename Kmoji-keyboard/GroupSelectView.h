//
//  GroupSelectView.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/5/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GroupSelectViewDelegate <UIScrollViewDelegate>

- (void)didSelectGroupWithName:(NSString *)groupName;

@end

@interface GroupSelectView : UIScrollView

@property (nonatomic, weak) id<GroupSelectViewDelegate> delegate;

- (void)setupWithGroups:(NSArray *)groupArray;
- (void)selectPreviousGroup;
- (void)selectGroupAtIndex:(NSUInteger)index;

@end
