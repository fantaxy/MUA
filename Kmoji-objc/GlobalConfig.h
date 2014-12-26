//
//  GlobalConfig.h
//  Kmoji-objc
//
//  Created by yangx2 on 10/23/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSURL *containerURL;
extern NSURL *sharedDirURL;
extern NSURL *sharedPlistURL;
extern NSURL *sharedEmotionsDirURL;
extern NSURL *emotionsDirURL;
extern NSURL *favoritePlistURL;

static NSString * const AppGroupID = @"group.fantaxy.mua";
static NSString const *PlistFileName = @"kmoj.plist";
static NSString const *OrderFileName = @"order.plist";
static NSString const *BannerImageName = @"banner.gif";
static NSString * const CoverImageName = @"cover.png";
static NSString const *EmotionDirName = @"emotions";
static NSString const *FavoriteGroupName = @"favorite";
static CGFloat  const HeightForCell = 92.0f;
static CGFloat  const HorizontalMargin = 20.0f;
