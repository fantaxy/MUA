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

@end
