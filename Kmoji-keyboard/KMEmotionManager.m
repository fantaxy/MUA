//
//  KMEmotionManager.m
//  Kmoji-objc
//
//  Created by yangx2 on 11/11/14.
//  Copyright (c) 2014 yang. All rights reserved.
//

#import "KMEmotionManager.h"
#import "GlobalConfig.h"
#import "KMEmotionSet.h"
#import "KMEmotionItem.h"
#import "KMEmotionTag.h"
#import "KMEmotionDataBase.h"
#import "KMAPIClient.h"
#import "KMURLHelper.h"

#import "AFHTTPRequestOperation.h"

static KMEmotionManager *sharedInstance;

@interface KMEmotionManager ()
{
}
@property (nonatomic, strong) NSMutableArray *emotionArray;
@property (nonatomic, strong) NSMutableArray *setArray;
@property (nonatomic, strong) NSMutableArray *tagArray;
@property (nonatomic, strong) NSMutableArray *downloadedEmotionSets;
@property (nonatomic, strong) NSMutableArray *downloadedEmotionTags;

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
        [self clearData];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:@"Version"];
    }
}

- (BOOL)checkIsInitialized
{
    NSString *dbPath = [[KMEmotionDataBase sharedInstance] getDbFilePath];
    BOOL dbFileExist = [[NSFileManager defaultManager] fileExistsAtPath:dbPath];
    BOOL emotionDirExist = [[NSFileManager defaultManager] fileExistsAtPath:emotionsDirURL.path];
    
    if (dbFileExist && emotionDirExist)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)clearData
{
    NSLog(@"Clear emotion data...");
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtURL:sharedEmotionsDirURL error:&error];
    if (success)
    {
        NSLog(@"Remove emotions directory success");
    }
    success = [fileManager removeItemAtURL:emotionsDirURL error:&error];
    if (success)
    {
        NSLog(@"Remove database file success");
    }
    success = [fileManager removeItemAtPath:[[KMEmotionDataBase sharedInstance] getDbFilePath] error:&error];
    if (success)
    {
        NSLog(@"Remove database file success");
    }
    success = [fileManager removeItemAtPath:[[KMEmotionDataBase sharedInstance] getSharedDbFilePath] error:&error];
    if (success)
    {
        NSLog(@"Remove shared database file success");
    }
    success = [fileManager removeItemAtURL:favoritePlistURL error:&error];
    if (!success)
    {
//        NSLog(@"Remove favorite plist failed with error %@", error);
    }
}

- (void)initializeData
{
    if (![self checkIsInitialized])
    {
        [self clearData];
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL success = [fileManager createDirectoryAtPath:emotionsDirURL.path withIntermediateDirectories:NO attributes:nil error:&error];
        if (success)
        {
            NSLog(@"Create emotion dir success");
        }
        success = [fileManager createDirectoryAtPath:sharedEmotionsDirURL.path withIntermediateDirectories:NO attributes:nil error:&error];
        if (success)
        {
            NSLog(@"Create shared emotion dir success");
        }
    }
    [[KMEmotionDataBase sharedInstance] initializeDb];
    self.emotionArray = [[KMEmotionDataBase sharedInstance] getEmotionItemArray];
    self.tagArray = [[KMEmotionDataBase sharedInstance] getEmotionTagArrayCollectingItems:NO];
    self.downloadedEmotionTags = [[KMEmotionDataBase sharedInstance] getDownloadedEmotionTagArray];
}

- (NSURLSessionDataTask *)createRefreshTaskWithCompletionBlock:(void (^)(NSError *))completionBlock
{
    return [[KMAPIClient sharedClient] GET:[KMURLHelper dataPath] parameters:nil success:^(NSURLSessionDataTask * __unused task, id JSON) {
        NSArray *postsFromResponse = [JSON valueForKeyPath:@"data"];
        for (NSDictionary *attributes in postsFromResponse) {
            KMEmotionItem *item = [[KMEmotionItem alloc] initWithAttributes:attributes];
            
            //找到之前保存的对象，检查是否需要更新
            BOOL alreadyExist = NO;
            for (__strong KMEmotionItem *eItem in self.emotionArray) {
                if ([eItem.imageName isEqualToString:item.imageName]) {
                    item.series = eItem.series;
                    item.tagSet = [item.tagSet setByAddingObjectsFromSet:eItem.tagSet];
                    if (![item isEqual:eItem]) {
                        eItem = item;
                        [eItem updatetoDb];
                    }
                    alreadyExist = YES;
                    break;
                }
            }
            if (!alreadyExist) {
                [self.emotionArray addObject:item];
                [item updatetoDb];
            }
            
            //检查是否有新增的tag
            for (NSString *tagName in item.tagSet) {
                KMEmotionTag *tag = [[KMEmotionTag alloc] initWithName:tagName thumbName:item.imageName];
                tag.addTime = [NSDate date];
                if (![self.tagArray containsObject:tag]) {
                    [tag updatetoDb];
                    [self.tagArray addObject:tag];
                }
            }
        }
        //无论是添加了表情还是添加了tag，都得重新读一遍tagArray
        self.tagArray = [[KMEmotionDataBase sharedInstance] getEmotionTagArrayCollectingItems:YES];
        
        if (completionBlock) {
            completionBlock(nil);
        }
    } failure:^(NSURLSessionDataTask *__unused task, NSError *error) {
        if (completionBlock) {
            completionBlock(error);
        }
    }];
}


#if 0
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
    self.emotionsData = plistData[@"emotions"];sharedPlistURL];
}

- (void)initializeData1
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObjects:
                     NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
    
    NSDirectoryEnumerator *enumerator = [fileMgr
                                         enumeratorAtURL:emotionsDirURL
                                         includingPropertiesForKeys:keys
                                         options:(NSDirectoryEnumerationSkipsPackageDescendants |
                                                  NSDirectoryEnumerationSkipsHiddenFiles)
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    int i = 0;
    NSError *error = nil;
    for (NSURL *url in enumerator) {
        NSNumber *isDirectory = nil;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue]) {
            NSString *dirName = nil;
            [url getResourceValue:&dirName forKey:NSURLLocalizedNameKey error:NULL];
//            KMEmotionSet *eSet = [KMEmotionSet new];
//            eSet.name = dirName;
//            eSet.desc = dirName;
//            eSet.tag = dirName;
//            eSet.order = i;
//            NSString *thumbPath = [[url path] stringByAppendingPathComponent:@"cover.gif"];
//            NSString *newThumbName = [[[NSUUID UUID] UUIDString] stringByAppendingString:@"-cover.gif"];
//            NSString *newThumbPath = [[url path] stringByAppendingPathComponent:newThumbName];
//            BOOL success = [fileMgr moveItemAtPath:thumbPath toPath:newThumbPath error:&error];
//            if (!success) {
//                NSLog(@"%s - %@", __func__, error);
//            }
//            eSet.thumbName = newThumbName;
//            [[KMEmotionDataBase sharedInstance] addEmotionSet:eSet];
            
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:url.path error:nil];
            for (NSString *path in array)
            {
                KMEmotionItem *item = [KMEmotionItem new];
                item.imageName = path;
                item.series = dirName;
                [item.tagSet addObject:dirName];
                item.isDownloaded = NO;
                [[KMEmotionDataBase sharedInstance] addEmotionItem:item];
            }
        }
    }
}

- (void)renameEmotionsUsingUUID
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObjects:
                     NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
    
    NSDirectoryEnumerator *enumerator = [fileMgr
                                         enumeratorAtURL:emotionsDirURL
                                         includingPropertiesForKeys:keys
                                         options:(NSDirectoryEnumerationSkipsPackageDescendants |
                                                  NSDirectoryEnumerationSkipsHiddenFiles)
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    for (NSURL *url in enumerator) {
        
        // Error checking is omitted for clarity.
        
        NSNumber *isDirectory = nil;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        if ([isDirectory boolValue]) {
            
            NSArray *array = [[NSFileManager defaultManager]
                              contentsOfDirectoryAtURL:url
                              includingPropertiesForKeys:nil
                              options:(NSDirectoryEnumerationSkipsHiddenFiles)
                              error:nil];
            dispatch_queue_t queue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_apply([array count], queue, ^(size_t i) {
                NSError *error = nil;
                NSString *newFileName = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".gif"];
                NSString *oldPath = [(NSURL *)array[i] path];
                NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
                BOOL success = [fileMgr moveItemAtPath:oldPath toPath:newPath error:&error];
                if (!success) {
                    NSLog(@"%s - %@", __func__, error);
                }
            });
        }
    }
}
#endif

- (AFHTTPRequestOperation *)getImageWithName:(NSString *)name completionBlock:(void (^)(NSString *, NSError *))completionBlock
{
    NSString *path = [emotionsDirURL.path stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (completionBlock) {
            completionBlock(path, nil);
            return nil;
        }
    }
    
    //下载
    NSURLRequest *request = [NSURLRequest requestWithURL:[KMURLHelper imageURLWithName:name]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded file to %@", path);
        if (completionBlock) {
            completionBlock(path, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
    
    [operation start];
    return operation;
}

- (void)downloadEmotionTag:(KMEmotionTag *)tag
{
    NSLog(@"Download emotion %@", tag);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *localPath;
    NSString *targetPath;
    
    for (KMEmotionItem *item in tag.itemArray)
    {
        localPath = [emotionsDirURL.path stringByAppendingPathComponent:item.imageName];
        targetPath = [sharedEmotionsDirURL.path stringByAppendingPathComponent:item.imageName];
        [self getImageWithName:item.imageName completionBlock:^(NSString *imagePath, NSError *error) {
            if (!error) {
                BOOL success = [fileManager copyItemAtPath:localPath toPath:targetPath error:&error];
                if (!success) {
                    NSLog(@"Copy emotion %@ to shared directory failed with error %@", item.imageName, error);
                }
                else {
                    item.isDownloaded = YES;
                    [item updatetoDb];
                    [item updatetoSharedDb];
                }
            }
        }];
    }
    [self.downloadedEmotionTags insertObject:tag atIndex:0];
    [self updateAllDownloadedTags];
}

- (void)downloadEmotionTagWithIndex:(NSInteger)index
{
    if (index < self.tagArray.count) {
        [self downloadEmotionTag:self.tagArray[index]];
    }
}

- (void)deleteEmotion:(KMEmotionTag *)tag
{
    NSLog(@"Delete emotions with tag %@", tag);
    if ([[KMEmotionDataBase sharedInstance] deleteDownloadedEmotionTag:tag] == SQLITE_OK)
    {
        [self.downloadedEmotionTags removeObject:tag];
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

- (void)updateAllDownloadedTags
{
    for (KMEmotionTag *tag in self.downloadedEmotionTags)
    {
        tag.order = (int)[self.downloadedEmotionTags indexOfObject:tag];
        [[KMEmotionDataBase sharedInstance] updateDownloadedEmotionTag:tag];
    }
}

- (void)moveEmotionFromIndex:(int)from toIndex:(int)to
{
    if (from >= self.downloadedEmotionTags.count || to >= self.downloadedEmotionTags.count)
    {
        NSLog(@"%s - Error: index out of range.", __func__);
        return;
    }
    if (from == to)
    {
        return;
    }
    KMEmotionTag *tag = self.downloadedEmotionTags[from];
    [self.downloadedEmotionTags removeObject:tag];
    [self.downloadedEmotionTags insertObject:tag atIndex:to];
    [self updateAllDownloadedTags];
    NSLog(@"Moved emotion %@ from %d to %d", tag, from, to);
}

- (NSArray *)getFavoriteEmotionArray
{
    NSArray *favoriteArray = [NSArray arrayWithContentsOfURL:favoritePlistURL];
    return favoriteArray;
}

- (NSUInteger)getEmotionTagsCount
{
    return self.tagArray.count;
}

- (KMEmotionTag *)getEmotionTagWithIndex:(NSInteger)index
{
    return [self.tagArray objectAtIndex:index];
}

- (NSArray *)getDownloadedEmotionTags
{
    if ([self.downloadedEmotionTags count])
    {
        return self.downloadedEmotionTags;
    }
    else
    {
        self.downloadedEmotionTags = [[KMEmotionDataBase sharedInstance] getDownloadedEmotionTagArray];
        return self.downloadedEmotionTags;
    }
}

- (BOOL)isDownloadedTag:(KMEmotionTag *)tag
{
    return [self.downloadedEmotionTags containsObject:tag];
}

//- (NSUInteger)getEmotionSetsCount
//{
//    return self.setArray.count;
//}
//
//- (KMEmotionSet *)getEmotionSetWithIndex:(NSInteger)index
//{
//    return [self.setArray objectAtIndex:index];
//}
//
//- (NSArray *)getDownloadedEmotionsets
//{
//    if ([self.downloadedEmotionSets count])
//    {
//        return self.downloadedEmotionSets;
//    }
//    else
//    {
//        //        self.downloadedEmotionSets = [[KMEmotionDataBase sharedInstance] getDownloadedEmotionSetArray];
//        return self.downloadedEmotionSets;
//    }
//}

@end
