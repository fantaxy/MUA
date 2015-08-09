//
//  KMEmotionManager.m
//  Kmoji-objc
//
//  Created by yangx2 on 11/11/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionManager.h"
#import "GlobalConfig.h"

static KMEmotionManager *sharedInstance;

@interface KMEmotionManager ()
{
}

@property (nonatomic, strong) NSMutableArray *favoriteEmotionArray;

@end

@implementation KMEmotionManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [KMEmotionManager new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _favoriteEmotionArray = [NSMutableArray arrayWithContentsOfURL:favoritePlistURL];
        if (!_favoriteEmotionArray)
        {
            _favoriteEmotionArray = [NSMutableArray new];
        }
    }
    return self;
}

- (NSArray *)getFavoriteItemArray
{
    return _favoriteEmotionArray;
}

- (void)addFavoriteItem:(NSString *)itemName
{
    if (![_favoriteEmotionArray containsObject:itemName])
    {
        [_favoriteEmotionArray insertObject:itemName atIndex:0];
        [_favoriteEmotionArray writeToFile:favoritePlistURL.path atomically:NO];
    }
}

+ (id)getSharedSettingsForKey:(NSString *)key
{
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    return [settingsDict objectForKey:key];
}

+ (void)setSharedSettingsWithValue:(id)value forKey:(NSString *)key
{
    NSDictionary *settingsDict = [NSMutableDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    if (!settingsDict) {
        settingsDict = [NSMutableDictionary new];
    }
    [settingsDict setValue:value forKey:key];
    [settingsDict writeToURL:sharedSettingsPlistURL atomically:YES];
}

+ (void)setSharedSettingsWithValueArray:(NSArray *)valueArray forKeyArray:(NSArray *)keyArray
{
    if (!valueArray.count || valueArray.count!=keyArray.count) {
        return;
    }
    NSDictionary *settingsDict = [NSMutableDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    if (!settingsDict) {
        settingsDict = [NSMutableDictionary new];
    }
    [valueArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [settingsDict setValue:obj forKey:keyArray[idx]];
    }];
    [settingsDict writeToURL:sharedSettingsPlistURL atomically:YES];
}

@end
