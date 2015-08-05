//
//  KMEmotionDataBase.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/3/1.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class KMEmotionTag;
@class KMEmotionItem;

@interface KMEmotionKeyboardDataBase : NSObject

+ (instancetype)sharedInstance;
- (NSArray *)getDownloadedEmotionTagArray;
- (void)updateEmotionItem:(KMEmotionItem *)item;
- (int)updateEmotionTag:(KMEmotionTag *)tag;


//- (void)updateEmotionSet:(KMEmotionSet *)set;

@end
