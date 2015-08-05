//
//  KMEmotionTag.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/6/27.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionTag.h"
#import "KMEmotionDataBase.h"
#import "KMEmotionManager.h"

@implementation KMEmotionTag

- (instancetype)initWithName:(NSString *)name thumbName:(NSString *)thunmName
{
    if (self = [super init]) {
        _name = name;
        _thumbName = thunmName;
    }
    return self;
}

- (NSString *)description
{
    return self.name;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[KMEmotionTag class]]) {
        KMEmotionTag *otherObject = (KMEmotionTag *)object;
        if ([otherObject.name isEqualToString:self.name]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)addTimeString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormat stringFromDate:self.addTime];
}

- (void)setAddTimeWithString:(NSString *)timeString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    self.addTime =[dateFormat dateFromString:timeString];
}

- (NSString *)desc
{
    if (!_desc) {
        return @"";
    }
    return _desc;
}

- (BOOL)isDownloaded
{
    return [[KMEmotionManager sharedManager] isDownloadedTag:self];
}

- (void)updatetoDb
{
    [[KMEmotionDataBase sharedInstance] updateEmotionTag:self];
}

@end
