//
//  KMEmotionManager.h
//  Kmoji-objc
//
//  Created by yangx2 on 11/11/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionManager : NSObject

@property (nonatomic, strong) NSArray *emotionsData;
@property (nonatomic, strong) NSMutableArray *downloadedEmotionInfo;
@property (nonatomic, assign) NSDictionary *selectedEmotion;

+ (instancetype)sharedManager;
- (void)downloadEmotion:(NSDictionary *)dict;
- (void)deleteEmotion:(NSDictionary *)dict;
- (NSArray *)deleteFavoriteEmotion:(NSArray *)array;
- (void)moveEmotionFromIndex:(int)from toIndex:(int)to;
- (NSArray *)getFavoriteEmotionArray;

@end
