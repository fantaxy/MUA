//
//  KMEmotionGridView.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/25/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KMEmotionGridViewDelegate <NSObject>

@optional
- (void)didFinishEditing;
- (void)didSelectEmotion:(NSString *)name;
- (void)sendSelectedEmotion;

@end

typedef NS_ENUM(NSUInteger, KMEmotionGridViewType) {
    GridViewType_Normal,
    GridViewType_Downloaded,
    GridViewType_Favorite
};

@interface KMEmotionGridView : UIView

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) id<KMEmotionGridViewDelegate> delegate;
@property (nonatomic, assign) KMEmotionGridViewType displayType;

- (void)setUpEmotionsWithArray:(NSArray *)emotionArray;
- (void)layoutEmotionTiles;
- (void)selectItemAtIndex:(int)index;

@end
