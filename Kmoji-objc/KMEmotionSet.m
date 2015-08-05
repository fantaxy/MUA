//
//  KMEmotionSet.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/2/24.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionSet.h"
#import "KMEmotionDataBase.h"

@implementation KMEmotionSet

- (instancetype)init
{
    if (self = [super init]) {
        self.order = 0;
    }
    return self;
}

- (NSString *)description
{
    return _name;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[KMEmotionSet class]]) {
        KMEmotionSet *eSet = (KMEmotionSet *)object;
        if ([self.name isEqualToString:eSet.name] && [self.desc isEqualToString:eSet.desc]) {
            return YES;
        }
    }
    return NO;
}

@end
