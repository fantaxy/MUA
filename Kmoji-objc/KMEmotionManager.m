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
@property (nonatomic, strong) NSMutableArray *tagArray;
@property (nonatomic, strong) NSMutableArray *downloadedEmotionSets;
@property (nonatomic, strong) NSMutableArray *downloadedEmotionTags;
@property (nonatomic, assign) BOOL hasAppGroupAccess;

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
    self.hasAppGroupAccess = YES;
    NSError *error = nil;
    [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedDirURL.path error:&error];
    if (257 == error.code)
    {
        self.hasAppGroupAccess = NO;
    }
    
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
    self.downloadedEmotionTags = [[KMEmotionDataBase sharedInstance] getDownloadedEmotionTagArray];
}

- (void)addTagForEmotionItem:(KMEmotionItem *)item
{
    //检查是否有新增的tag
    for (NSString *tagName in item.tagSet) {
        KMEmotionTag *tag = [[KMEmotionTag alloc] initWithName:tagName thumbName:item.imageName];
        tag.addTime = [NSDate date];
        if (![self.tagArray containsObject:tag]) {
            //新增tag
            tag.itemArray = [NSMutableArray arrayWithObjects:item, nil];
            [self.tagArray addObject:tag];
        }
        else {
            //重复tag
            NSUInteger index = [self.tagArray indexOfObject:tag];
            if (index < self.tagArray.count) {
                KMEmotionTag *tag = (KMEmotionTag *)self.tagArray[index];
                NSMutableArray *itemArray = [NSMutableArray arrayWithArray:tag.itemArray];
                [itemArray addObject:item];
                tag.itemArray = itemArray;
            }
        }
    }
}

- (NSURLSessionDataTask *)createRefreshTaskWithCompletionBlock:(void (^)(NSError *))completionBlock
{
    return [[KMAPIClient sharedClient] GET:[KMURLHelper dataPath] parameters:nil success:^(NSURLSessionDataTask * __unused task, id JSON) {
        NSArray *postsFromResponse = [JSON valueForKeyPath:@"data"];
        
        if (postsFromResponse.count) {
            
            self.tagArray = [NSMutableArray new];
            
            for (NSDictionary *attributes in postsFromResponse) {
                KMEmotionItem *item = [[KMEmotionItem alloc] initWithAttributes:attributes];
                [self addTagForEmotionItem:item];
            }
            
            [NSKeyedArchiver archiveRootObject:self.tagArray toFile:cacheDataURL.path];
        }
        
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
    path = [sharedEmotionsDirURL.path stringByAppendingPathComponent:name];
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
    NSString *targetPath;
    
    for (KMEmotionItem *item in tag.itemArray)
    {
        targetPath = [sharedEmotionsDirURL.path stringByAppendingPathComponent:item.imageName];
        [self getImageWithName:item.imageName completionBlock:^(NSString *imagePath, NSError *error) {
            if (!error) {
                BOOL exist = [fileManager fileExistsAtPath:targetPath];
                if (!exist) {
                    BOOL success = [fileManager copyItemAtPath:imagePath toPath:targetPath error:&error];
                    if (!success) {
                        NSLog(@"Copy emotion %@ to shared directory failed with error %@", item.imageName, error);
                        return;
                    }
                }
                item.isDownloaded = YES;
                [item updatetoDb];
                [item updatetoSharedDb];
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
    //选中新下载的分类
    [KMEmotionManager setSharedSettingsWithValue:@(1) forKey:@"selectedGroup"];
    [KMEmotionManager setSharedSettingsWithValue:@(0) forKey:@"selectedPage"];
}

- (void)addEmotion:(NSData *)imageData withTag:(NSString *)tag
{
    if (!imageData || !tag || !tag.length) {
        return;
    }
    NSString *emotionName = [[NSUUID UUID] UUIDString];
    NSString *path = nil;
    if (self.hasAppGroupAccess) {
        path = [sharedEmotionsDirURL.path stringByAppendingPathComponent:emotionName];
    }
    else {
        path = [emotionsDirURL.path stringByAppendingPathComponent:emotionName];
    }
    BOOL succeed = [imageData writeToFile:path atomically:YES];
    if (succeed) {
        NSLog(@"%s - image: %@ tag: %@", __func__, emotionName, tag);
        KMEmotionItem *eItem = [KMEmotionItem new];
        eItem.imageName = emotionName;
        eItem.isDownloaded = YES;
        NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:[eItem stringTotagSet:tag]];
        eItem.tagSet = [[orderedSet set] mutableCopy];
        [eItem updatetoSharedDb];
        
        for (NSString *tagName in eItem.tagSet) {
            KMEmotionTag *tag = [[KMEmotionTag alloc] initWithName:tagName thumbName:emotionName];
            tag.itemArray = [NSArray arrayWithObject:eItem];
            tag.addTime = [NSDate date];
            if ([self.downloadedEmotionTags containsObject:tag]) {
                NSUInteger index = [self.downloadedEmotionTags indexOfObject:tag];
                KMEmotionTag *existedTag = self.downloadedEmotionTags[index];
                existedTag.itemArray = [tag.itemArray arrayByAddingObjectsFromArray:existedTag.itemArray];
            }
            else {
                [self.downloadedEmotionTags insertObject:tag atIndex:0];
            }
        }
        [self updateAllDownloadedTags];
    }
}

- (void)deleteEmotionTag:(KMEmotionTag *)tag
{
    NSLog(@"Delete emotions with tag %@", tag);
    if ([[KMEmotionDataBase sharedInstance] deleteDownloadedEmotionTag:tag] == SQLITE_OK)
    {
        [self.downloadedEmotionTags removeObject:tag];
        NSMutableArray *deletedItems = [NSMutableArray new];
        for (KMEmotionItem *item in tag.itemArray) {
            [item removeTag:tag.name];
            //如果还属于其它标签则不删除
            if ([item.tagSet count]) {
                [item updatetoSharedDb];
            }
            else {
                [self deleteEmotionItem:item];
                [deletedItems addObject:item];
            }
        }
        [self deleteFavoriteEmotion:deletedItems];
    }
}

- (void)deleteEmotionItem:(KMEmotionItem *)item
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *itemPath = [sharedEmotionsDirURL.path stringByAppendingPathComponent:item.imageName];
    BOOL success = [fileManager removeItemAtPath:itemPath error:&error];
    if (success)
    {
        NSLog(@"Remove emotion item %@ success", item);
    }
    [[KMEmotionDataBase sharedInstance] deleteDownloadedEmotionItem:item];
}

- (NSArray *)deleteFavoriteEmotion:(NSArray *)itemArray
{
    NSLog(@"Delete favorite emotion %@", itemArray);
    NSMutableArray *favoriteArray = [[self getFavoriteEmotionArray] mutableCopy];
    for (KMEmotionItem *item in itemArray) {
        [favoriteArray removeObject:item.imageName];
    }
    BOOL success = [favoriteArray writeToFile:favoritePlistURL.path atomically:NO];
    if (!success)
    {
        NSLog(@"Write favorite plist failed.");
    }
    return favoriteArray;
}

- (void)updateAllDownloadedTags
{
    for (KMEmotionTag *tag in self.downloadedEmotionTags)
    {
        tag.order = (int)[self.downloadedEmotionTags indexOfObject:tag];
        [tag updatetoSharedDB];
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

- (NSArray *)getEmotionTags
{
    if (!self.tagArray) {
        self.tagArray = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheDataURL.path];
    }
    return self.tagArray;
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

+ (id)getSharedSettingsForKey:(NSString *)key
{
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    return [settingsDict objectForKey:key];
}

#pragma mark - Shared setting

+ (void)setSharedSettingsWithValue:(id)value forKey:(NSString *)key
{
    NSDictionary *settingsDict = [NSMutableDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    if (!settingsDict) {
        settingsDict = [NSMutableDictionary new];
    }
    [settingsDict setValue:value forKey:key];
    [settingsDict writeToURL:sharedSettingsPlistURL atomically:YES];
}

+ (void)setSharedSettingsWithValueArray:(NSArray *)valueArray forKeyArray:(NSArray *)keyArray
{
    if (!valueArray.count || valueArray.count!=keyArray.count) {
        return;
    }
    NSDictionary *settingsDict = [NSMutableDictionary dictionaryWithContentsOfURL:sharedSettingsPlistURL];
    if (!settingsDict) {
        settingsDict = [NSMutableDictionary new];
    }
    [valueArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [settingsDict setValue:obj forKey:keyArray[idx]];
    }];
    [settingsDict writeToURL:sharedSettingsPlistURL atomically:YES];
}

@end
