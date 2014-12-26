//
//  KMEmotionView.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/9/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KMEmotionView : UIView

@property (nonatomic, strong) NSMutableArray *favoriteEmotionArray;

- (void)setupEmotionsWithGroupName:(NSString *)groupName;
- (void)setupEmotionsForFavorite;
- (void)scrollToPreviousPage;

@end
