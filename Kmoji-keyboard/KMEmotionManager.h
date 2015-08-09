//
//  KMEmotionManager.h
//  Kmoji-objc
//
//  Created by yangx2 on 11/11/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMEmotionManager : NSObject

+ (instancetype)sharedManager;
+ (id)getSharedSettingsForKey:(NSString *)key;
+ (void)setSharedSettingsWithValue:(id)value forKey:(NSString *)key;
+ (void)setSharedSettingsWithValueArray:(NSArray *)valueArray forKeyArray:(NSArray *)keyArray;

- (NSArray *)getFavoriteItemArray;
- (void)addFavoriteItem:(NSString *)itemName;

@end
