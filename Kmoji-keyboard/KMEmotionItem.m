//
//  KMEmotionItem.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionItem.h"
#import "KMEmotionKeyboardDataBase.h"

@implementation KMEmotionItem

- (instancetype)init
{
    if (self = [super init]){
    }
    return self;
}

- (NSString *)tagSetToString
{
    return [[self.tagSet allObjects] componentsJoinedByString:@","];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@", _series, _imageName];
}

- (void)updatetoDb
{
    [[KMEmotionKeyboardDataBase sharedInstance] updateEmotionItem:self];
}

@end
