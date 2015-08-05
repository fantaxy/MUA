//
//  KMEmotionDataBase.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/3/1.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionKeyboardDataBase.h"
#import "KMEmotionItem.h"
#import "GlobalConfig.h"
#import "KMEmotionTag.h"

#define kEmotionSharedDatabase @"mua_shared.sqlite3"
//#define kEmotionSetDownloadedTable @"emotion_series_downloaded"
#define kEmotionItemDownloadedTable @"emotion_items_downloaded"
#define kEmotionTagDownloadedTable @"emotion_tags_downloaded"

@interface KMEmotionKeyboardDataBase ()
{
    sqlite3 *_shared_database;
}

@end

@implementation KMEmotionKeyboardDataBase

static KMEmotionKeyboardDataBase *staticInstance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [KMEmotionKeyboardDataBase new];
    });
    return staticInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc
{
    [self closeSharedDb];
}

- (NSArray *)getDownloadedEmotionTagArray
{
    if (SQLITE_OK == [self openSharedDb]) {
        NSMutableArray *result = [NSMutableArray new];
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY my_order", kEmotionTagDownloadedTable];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_shared_database, [query UTF8String], -1, &statement, nil)
            == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *nameChars = (char *) sqlite3_column_text(statement, 1);
                int order = sqlite3_column_int(statement, 2);
                char *thumbNameChars = (char *) sqlite3_column_text(statement, 3);
                KMEmotionTag *tag = [KMEmotionTag new];
                tag.name = [[NSString alloc] initWithUTF8String:nameChars];
                tag.order = order;
                tag.thumbName = [[NSString alloc] initWithUTF8String:thumbNameChars];
                tag.itemArray = [self getEmotionItemArrayWithTag:tag.name];
                [result addObject:tag];
            }
            sqlite3_finalize(statement);
        }
        [self closeSharedDb];
        return result;
    }
    else
    {
        return nil;
    }
}

- (NSMutableArray *)getEmotionItemArrayWithTag:(NSString *)tag
{
    NSMutableArray *result = [NSMutableArray new];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE tag LIKE \"%%%@%%\"", kEmotionItemDownloadedTable, tag];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_shared_database, [query UTF8String], -1, &statement, nil)
        == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *nameChars = (char *) sqlite3_column_text(statement, 1);
            int clickCount = (BOOL) sqlite3_column_text(statement, 2);
            char *series = (char *) sqlite3_column_text(statement, 3);
            char *tags = (char *) sqlite3_column_text(statement, 4);
            KMEmotionItem *eItem = [KMEmotionItem new];
            eItem.imageName = [[NSString alloc] initWithUTF8String:nameChars];
            eItem.clickCount = clickCount;
            eItem.series = [[NSString alloc] initWithUTF8String:series];
            NSOrderedSet *orderedSet = [[NSOrderedSet alloc] initWithArray:[[[NSString alloc] initWithUTF8String:tags]componentsSeparatedByString:@","]];
            eItem.tagSet = [orderedSet set];
            [result addObject:eItem];
        }
        sqlite3_finalize(statement);
    }
    return result;
}

- (int)updateEmotionTag:(KMEmotionTag *)tag
{
    int rc = [self openSharedDb];
    if (rc == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        const char *query = "UPDATE emotion_tags_downloaded SET my_order=?, thumb_name=? where name=?";
        if(sqlite3_prepare_v2(_shared_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
        {
            /*
             * 参数1为query的句柄,
             * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
             * 参数3为参数的值
             * 参数4为值的长度,-1表示以\0为结束符
             * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
             */
            sqlite3_bind_text(updateStmt, 3, [tag.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt,  1, tag.order);
            sqlite3_bind_text(updateStmt, 2, [tag.thumbName UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        if(SQLITE_DONE != sqlite3_step(updateStmt))
        {
            NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_shared_database));
        }
        sqlite3_finalize(updateStmt);
        [self closeSharedDb];
        return SQLITE_OK;
    }
    return rc;
}

- (void)updateEmotionItem:(KMEmotionItem *)item
{
    sqlite3_stmt *updateStmt;
    const char *query = "UPDATE emotion_items SET click_times=?, series=?, tag=? where name=?";
    if(sqlite3_prepare_v2(_shared_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
    {
        /*
         * 参数1为query的句柄,
         * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
         * 参数3为参数的值
         * 参数4为值的长度,-1表示以\0为结束符
         * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
         */
        sqlite3_bind_text(updateStmt, 4, [item.imageName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateStmt,  1, item.clickCount);
        sqlite3_bind_text(updateStmt, 2, [item.series UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [item.tagSetToString UTF8String], -1, SQLITE_TRANSIENT);
    }
    
    if(SQLITE_DONE != sqlite3_step(updateStmt))
    {
        NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_shared_database));
    }
    sqlite3_finalize(updateStmt);
}

# pragma mark - private method

- (int)openSharedDb
{
    int rc=0;
    
    rc = sqlite3_open_v2([[self getSharedDbFilePath] cStringUsingEncoding:NSUTF8StringEncoding], &_shared_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != rc)
    {
        sqlite3_close(_shared_database);
        NSLog(@"Failed to open shared db connection");
    }
    return rc;
}

- (void)closeSharedDb
{
    sqlite3_close(_shared_database);
}

- (NSString *)getSharedDbFilePath
{
    NSString *path = [sharedDirURL.path stringByAppendingPathComponent:kEmotionSharedDatabase];
    
    return path;
}

//- (void)updateEmotionSet:(KMEmotionSet *)set
//{
//    sqlite3_stmt *updateStmt;
//    const char *query = "UPDATE emotion_series SET desc=?, my_order=?, thumb_name=?, tag=?, downloaded=? where name=?";
//    if(sqlite3_prepare_v2(_shared_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
//    {
//        /*
//         * 参数1为query的句柄,
//         * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
//         * 参数3为参数的值
//         * 参数4为值的长度,-1表示以\0为结束符
//         * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
//         */
//        sqlite3_bind_text(updateStmt, 6, [set.name UTF8String], -1, SQLITE_TRANSIENT);
//        sqlite3_bind_text(updateStmt, 1, [set.desc UTF8String], -1, SQLITE_TRANSIENT);
//        sqlite3_bind_int(updateStmt,  2, (int)set.order);
//        sqlite3_bind_text(updateStmt, 3, [set.thumbName UTF8String], -1, SQLITE_TRANSIENT);
//        sqlite3_bind_text(updateStmt, 4, [set.tag UTF8String], -1, SQLITE_TRANSIENT);
//        sqlite3_bind_int(updateStmt,  5, set.isDownloaded);
//    }
//    
//    if(SQLITE_DONE != sqlite3_step(updateStmt))
//    {
//        NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_shared_database));
//    }
//    sqlite3_finalize(updateStmt);
//}

@end
