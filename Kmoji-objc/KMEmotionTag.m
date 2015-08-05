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

static NSString *kTagName  = @"kTagName";
static NSString *kThumbName = @"kThumbName";
static NSString *kDescription     = @"kDescription";
static NSString *kAddTime      = @"kAddTime";
static NSString *kItemArray      = @"kItemArray";
static NSString *kOrder      = @"kOrder";

- (instancetype)initWithName:(NSString *)name thumbName:(NSString *)thunmName
{
    if (self = [super init]) {
        _name = name;
        _thumbName = thunmName;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self.name = [aDecoder decodeObjectForKey:kTagName];
    self.thumbName = [aDecoder decodeObjectForKey:kThumbName];
    self.desc = [aDecoder decodeObjectForKey:kDescription];
    self.addTime = [aDecoder decodeObjectForKey:kAddTime];
    self.itemArray = [aDecoder decodeObjectForKey:kItemArray];
    self.order = [aDecoder decodeIntForKey:kOrder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:kTagName];
    [aCoder encodeObject:self.thumbName forKey:kThumbName];
    [aCoder encodeObject:self.desc forKey:kDescription];
    [aCoder encodeObject:self.addTime forKey:kAddTime];
    [aCoder encodeObject:self.itemArray forKey:kItemArray];
    [aCoder encodeInt:self.order forKey:kOrder];
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

- (void)updatetoSharedDB
{
    [[KMEmotionDataBase sharedInstance] updateDownloadedEmotionTag:self];
}

@end
