//
//  KMEmotionDataBase.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/3/1.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class KMEmotionItem;
@class KMEmotionTag;

@interface KMEmotionDataBase : NSObject

+ (instancetype)sharedInstance;

- (NSString *)getDbFilePath;
- (NSString *)getSharedDbFilePath;
- (void)initializeDb;
- (int)updateDownloadedEmotionItem:(KMEmotionItem *)item;
//传入是否同时查询所有包含改tag的item
- (NSMutableArray *)getEmotionTagArrayCollectingItems:(BOOL)collectingItems;
- (NSMutableArray *)getEmotionItemArray;
- (NSMutableArray *)getDownloadedEmotionTagArray;
- (void)updateEmotionItem:(KMEmotionItem *)item;
- (void)updateEmotionTag:(KMEmotionTag *)tag;
- (int)updateDownloadedEmotionTag:(KMEmotionTag *)tag;
- (int)insertDownloadedEmotionTag:(KMEmotionTag *)tag;
- (int)deleteDownloadedEmotionTag:(KMEmotionTag *)tag;
- (int)deleteDownloadedEmotionItem:(KMEmotionItem *)item;

//- (int)addEmotionSet:(KMEmotionSet *)set;
//- (int)addDownloadedEmotionSet:(KMEmotionSet *)set;
//- (int)deleteDownloadedEmotionSet:(KMEmotionSet *)set;
//- (NSMutableArray *)getEmotionSetArray;
//- (void)updateEmotionSet:(KMEmotionSet *)set;
//- (int)updateDownloadedEmotionSet:(KMEmotionSet *)set;
//- (NSMutableArray *)getDownloadedEmotionSetArray;

@end
