//
//  KMEmotionItem.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionItem.h"
#import "KMEmotionDataBase.h"

@implementation KMEmotionItem

- (instancetype)init
{
    if (self = [super init]){
        _tagArray = [NSMutableArray new];
    }
    return self;
}

- (NSString *)tagArrayToString
{
    return [self.tagArray componentsJoinedByString:@","];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@", _series, _imageName];
}

- (void)updatetoDb
{
    [[KMEmotionDataBase sharedInstance] updateEmotionItem:self];
}

@end
