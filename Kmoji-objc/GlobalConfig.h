//
//  GlobalConfig.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/23/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BLUE_COLOR UIColorWithRGB(28, 178, 255)
#define GRAY_COLOR UIColorWithRGB(240, 240, 240)
#define GRAY_COLOR_SETTING UIColorWithRGB(247, 247, 247)
#define BLACK_COLOR UIColorWithRGB(1, 1, 1)
#define TABBAR_TITLE_FONT_SIZE (13)

extern NSURL *containerURL;
extern NSURL *sharedDirURL;
extern NSURL *sharedEmotionsDirURL;
extern NSURL *localEmotionsDirURL;
extern NSURL *emotionsDirURL;
extern NSURL *favoritePlistURL;
extern NSURL *cacheDataURL;

static NSString * const AppGroupID = @"group.fantaxy.mua";
static NSString const *PlistFileName = @"kmoj.plist";
static NSString const *OrderFileName = @"order.plist";
static NSString const *BannerImageName = @"banner.gif";
static NSString * const CoverImageName = @"cover.png";
static NSString const *EmotionDirName = @"emotions";
static NSString const *FavoriteGroupName = @"favorite";
static CGFloat  const HeightForCell = 70.0f;
static CGFloat  const HorizontalMargin = 20.0f;
