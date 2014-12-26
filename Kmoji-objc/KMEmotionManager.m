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
        [self checkVersion];
        [self initializeData];        
    }
    return self;
}

- (void)checkVersion
{
    NSString *currentVersion = @"1.0.0";
    NSString *previousVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"Version"];
    if (!previousVersion || [@"" isEqualToString:previousVersion] || ![currentVersion isEqualToString:previousVersion])
    {
        [self clearSharedData];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:@"Version"];
    }
}

- (BOOL)checkIsInitialized
{
    BOOL sharedPlistExist = [[NSFileManager defaultManager] fileExistsAtPath:sharedPlistURL.path];
    BOOL emotionDirExist = [[NSFileManager defaultManager] fileExistsAtPath:sharedEmotionsDirURL.path];
    if (sharedPlistExist && emotionDirExist)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)clearSharedData
{
    NSLog(@"Initialize emotion data...");
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:sharedPlistURL error:&error];
    BOOL success = [fileManager removeItemAtURL:sharedPlistURL error:&error];
    if (!success)
    {
        NSLog(@"Remove shared plist failed with error %@", error);
    }
    success = [fileManager removeItemAtURL:sharedEmotionsDirURL error:&error];
    if (!success)
    {
        NSLog(@"Remove emotions directory failed with error %@", error);
    }
    success = [fileManager removeItemAtURL:favoritePlistURL error:&error];
    if (!success)
    {
        NSLog(@"Remove favorite plist failed with error %@", error);
    }
}

- (void)initializeData
{
    if (![self checkIsInitialized])
    {
        [self clearSharedData];
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager createDirectoryAtPath:sharedEmotionsDirURL.path withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success)
        {
            NSLog(@"Create shared emotion dir failed with error: %@", error);
        }
    }
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"emotions" withExtension:@"plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:plistURL.path];
    self.emotionsData = plistData[@"emotions"];
    self.downloadedEmotionInfo = [NSMutableArray arrayWithContentsOfURL:sharedPlistURL];
    if (!self.downloadedEmotionInfo)
    {
        NSLog(@"No shared plist yet.");
        self.downloadedEmotionInfo = [NSMutableArray new];
    }
}

- (void)downloadEmotion:(NSDictionary *)dict
{
    NSLog(@"Download emotion %@", dict);
    NSString *folderName = dict[@"folder"];
    NSString *localPath = [NSString stringWithFormat:@"%@/%@", emotionsDirURL.path, folderName];
    NSString *targetPath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, folderName];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager copyItemAtPath:localPath toPath:targetPath error:&error];
    if (!success)
    {
        NSLog(@"Copy emotion to shared directory failed with error %@", error);
    }
    
    [self.downloadedEmotionInfo insertObject:dict atIndex:0];
    success = [self.downloadedEmotionInfo writeToFile:sharedPlistURL.path atomically:NO];
    if (!success)
    {
        NSLog(@"Write shared plist failed with error %@", error);
        return;
    }
}

- (void)deleteEmotion:(NSDictionary *)dict
{
    NSLog(@"Delete emotion %@", dict);
    NSString *folderName = dict[@"folder"];
    NSString *targetPath = [NSString stringWithFormat:@"%@/%@", sharedEmotionsDirURL.path, folderName];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:targetPath error:&error];
    if (!success)
    {
        NSLog(@"Remove downloaded emotion %@ failed with error %@", folderName, error);
    }
    [self.downloadedEmotionInfo removeObject:dict];
    success = [self.downloadedEmotionInfo writeToFile:sharedPlistURL.path atomically:NO];
    if (!success)
    {
        NSLog(@"Write shared plist failed.");
    }
}

- (NSArray *)deleteFavoriteEmotion:(NSArray *)array
{
    NSLog(@"Delete favorite emotion %@", array);
    NSMutableArray *favoriteArray = [NSMutableArray arrayWithContentsOfURL:favoritePlistURL];
    [favoriteArray removeObjectsInArray:array];
    BOOL success = [favoriteArray writeToFile:favoritePlistURL.path atomically:NO];
    if (!success)
    {
        NSLog(@"Write favorite plist failed.");
    }
    return [self getFavoriteEmotionArray];
}

- (void)moveEmotionFromIndex:(int)from toIndex:(int)to
{
    NSLog(@"Move emotion from %d to %d", from, to);
    if (from >= self.downloadedEmotionInfo.count || to >= self.downloadedEmotionInfo.count)
    {
        NSLog(@"%s - Error: index out of range.", __func__);
        return;
    }
    if (from == to)
    {
        return;
    }
    id target = self.downloadedEmotionInfo[from];
    [self.downloadedEmotionInfo removeObject:target];
    [self.downloadedEmotionInfo insertObject:target atIndex:to];
    NSError *error;
    BOOL success = [self.downloadedEmotionInfo writeToFile:sharedPlistURL.path atomically:NO];
    if (!success)
    {
        NSLog(@"Write shared plist failed with error %@", error);
        return;
    }
}

- (NSArray *)getFavoriteEmotionArray
{
    NSArray *favoriteArray = [NSArray arrayWithContentsOfURL:favoritePlistURL];
    return favoriteArray;
}

@end
