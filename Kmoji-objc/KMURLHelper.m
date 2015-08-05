//
//  KMURLHelper.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/6/28.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMURLHelper.h"

static NSString * const KMAPIBaseURLString = @"http://www.muabiaoqing.com:8080/";

@implementation KMURLHelper

+ (NSURL *)baseURL
{
    return [NSURL URLWithString:KMAPIBaseURLString];
}

+ (NSString *)dataPath
{
    return @"data/all";
}

+ (NSString *)imagePathWithName:(NSString *)name
{
    return [@"emotions" stringByAppendingPathComponent:name];
}

+ (NSURL *)imageURLWithName:(NSString *)name
{
    NSString *imagePath = [KMURLHelper imagePathWithName:name];
    return [NSURL URLWithString:imagePath relativeToURL:[KMURLHelper baseURL]];
}

@end
