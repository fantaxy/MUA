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

static NSString *kImageName  = @"kImageName";
static NSString *kIsDownloaded = @"kIsDownloaded";
static NSString *kClickCount     = @"kClickCount";
static NSString *kSeries      = @"kSeries";
static NSString *kTagSet      = @"kTagSet";

- (instancetype)init
{
    if (self = [super init]){
    }
    return self;
}

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.imageName = [attributes valueForKeyPath:@"Name"];
    self.series = [attributes valueForKeyPath:@"Series"];
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:[self stringTotagSet:[attributes valueForKey:@"Tags"]]];
    self.tagSet = [[orderedSet set] mutableCopy];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self.imageName = [aDecoder decodeObjectForKey:kImageName];
    self.isDownloaded = [aDecoder decodeBoolForKey:kIsDownloaded];
    self.clickCount = [aDecoder decodeIntForKey:kClickCount];
    self.series = [aDecoder decodeObjectForKey:kSeries];
    self.tagSet = [aDecoder decodeObjectForKey:kTagSet];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.imageName forKey:kImageName];
    [aCoder encodeBool:self.isDownloaded forKey:kIsDownloaded];
    [aCoder encodeInt:self.clickCount forKey:kClickCount];
    [aCoder encodeObject:self.series forKey:kSeries];
    [aCoder encodeObject:self.tagSet forKey:kTagSet];
}

- (NSString *)tagSetToString
{
    return [[self.tagSet allObjects] componentsJoinedByString:@","];
}

- (NSArray *)stringTotagSet:(NSString *)string
{
    string =  [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (string && string.length) {
        return [string componentsSeparatedByString:@" "];
    }
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@", _imageName, self.tagSetToString];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[KMEmotionItem class]]) {
        KMEmotionItem *otherObject = (KMEmotionItem *)object;
        if ([otherObject.imageName isEqualToString:self.imageName] &&
            [otherObject.series isEqualToString:self.series] &&
            [otherObject.tagSet isEqualToSet:self.tagSet]) {
            return YES;
        }
    }
    return NO;
}

- (void)updatetoDb
{
    [[KMEmotionDataBase sharedInstance] updateEmotionItem:self];
}

- (void)updatetoSharedDb
{
    [[KMEmotionDataBase sharedInstance] updateDownloadedEmotionItem:self];
}

- (void)removeTag:(NSString *)tag
{
    [self.tagSet removeObject:tag];
}

@end
