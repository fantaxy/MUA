//
//  KMEmotionDataBase.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/3/1.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class KMEmotionSet;
@class KMEmotionItem;

@interface KMEmotionDataBase : NSObject

+ (instancetype)sharedInstance;
- (int)addEmotionSet:(KMEmotionSet *)set;
- (int)addDownloadedEmotionSet:(KMEmotionSet *)set;
- (int)addEmotionItem:(KMEmotionItem *)item;
- (NSArray *)getEmotionSetArray;
- (NSArray *)getDownloadedEmotionSetArray;
- (void)updateEmotionItem:(KMEmotionItem *)item;
- (void)updateEmotionSet:(KMEmotionSet *)set;

@end
