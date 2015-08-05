//
//  KMEmotionManager.h
//  Kmoji-objc
//
//  Created by yangx2 on 11/11/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KMEmotionItem;
@class KMEmotionTag;
@class AFURLConnectionOperation;

@interface KMEmotionManager : NSObject

@property (nonatomic, assign) KMEmotionTag *selectedEmotion;

+ (instancetype)sharedManager;
- (NSURLSessionDataTask *)createRefreshTaskWithCompletionBlock:(void (^)(NSError *error))completionBlock;
- (void)downloadEmotionTag:(KMEmotionTag *)tag;
- (void)downloadEmotionTagWithIndex:(NSInteger)index;
- (void)deleteEmotion:(NSDictionary *)dict;
- (NSArray *)deleteFavoriteEmotion:(NSArray *)array;
- (void)moveEmotionFromIndex:(int)from toIndex:(int)to;
- (NSArray *)getFavoriteEmotionArray;
- (NSUInteger)getEmotionTagsCount;
- (KMEmotionTag *)getEmotionTagWithIndex:(NSInteger)index;
- (NSArray *)getDownloadedEmotionTags;
- (BOOL)isDownloadedTag:(KMEmotionTag *)tag;

- (AFURLConnectionOperation *)getImageWithName:(NSString *)name completionBlock:(void (^)(NSString *imagePath, NSError *error))completionBlock;


//- (NSArray *)getDownloadedEmotionsets;
//- (void)downloadEmotion:(KMEmotionSet *)set;
//- (NSUInteger)getEmotionSetsCount;
//- (KMEmotionSet *)getEmotionSetWithIndex:(NSInteger)index;
//- (void)downloadEmotionSetWithIndex:(NSInteger)index;

@end
