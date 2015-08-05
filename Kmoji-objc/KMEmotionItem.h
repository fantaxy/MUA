//
//  KMEmotionItem.h
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionItem : NSObject<NSCoding>

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic) BOOL isDownloaded;
@property (nonatomic) int clickCount;
@property (nonatomic, strong) NSString *series;
@property (nonatomic, strong) NSMutableSet *tagSet;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

- (NSString *)tagSetToString;
- (NSArray *)stringTotagSet:(NSString *)string;
- (void)updatetoDb;
- (void)updatetoSharedDb;
- (void)removeTag:(NSString *)tag;

@end
