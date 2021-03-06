//
//  KMEmotionDataBase.m
//  Kmoji-objc
//
//  Created by Fanta Xu on 15/3/1.
//  Copyright (c) 2015年 yang. All rights reserved.
//

#import "KMEmotionDataBase.h"
#import "KMEmotionItem.h"
#import "GlobalConfig.h"
#import "KMEmotionTag.h"

#define kEmotionDatabase @"mua.sqlite3"
#define kEmotionSharedDatabase @"mua_shared.sqlite3"
#define kEmotionSetTable @"emotion_series"
#define kEmotionSetDownloadedTable @"emotion_series_downloaded"
#define kEmotionItemTable @"emotion_items"
#define kEmotionItemDownloadedTable @"emotion_items_downloaded"
#define kEmotionTagTable @"emotion_tags"
#define kEmotionTagDownloadedTable @"emotion_tags_downloaded"

@interface KMEmotionDataBase ()
{
    sqlite3 *_database;
    sqlite3 *_shared_database;
}

@end

@implementation KMEmotionDataBase

static KMEmotionDataBase *staticInstance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [KMEmotionDataBase new];
    });
    return staticInstance;
}

- (void)initializeDb
{
    [self openDb];
    [self createTable];
}

- (void)dealloc
{
    [self closeDb];
}

- (NSMutableArray *)getEmotionItemArray
{
    NSMutableArray *result = [NSMutableArray new];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@", kEmotionItemTable];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
        == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *nameChars = (char *) sqlite3_column_text(statement, 1);
            BOOL downloaded = (BOOL) sqlite3_column_text(statement, 2);
            char *series = (char *) sqlite3_column_text(statement, 3);
            char *tags = (char *) sqlite3_column_text(statement, 4);
            KMEmotionItem *eItem = [KMEmotionItem new];
            eItem.imageName = [[NSString alloc] initWithUTF8String:nameChars];
            eItem.isDownloaded = downloaded;
            eItem.series = [[NSString alloc] initWithUTF8String:series];
            NSOrderedSet *orderedSet = [[NSOrderedSet alloc] initWithArray:[[[NSString alloc] initWithUTF8String:tags]componentsSeparatedByString:@","]];
            eItem.tagSet = [[orderedSet set] mutableCopy];
            [result addObject:eItem];
        }
        sqlite3_finalize(statement);
    }
    return result;
}

- (NSMutableArray *)getEmotionTagArrayCollectingItems:(BOOL)collectingItems
{
    NSMutableArray *result = [NSMutableArray new];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY add_time DESC", kEmotionTagTable];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
        == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *nameChars = (char *) sqlite3_column_text(statement, 1);
            char *thumbNameChars = (char *) sqlite3_column_text(statement, 2);
            char *descChars = (char *) sqlite3_column_text(statement, 3);
            char *addTimeChars = (char *) sqlite3_column_text(statement, 5);
            KMEmotionTag *tag = [KMEmotionTag new];
            tag.name = [[NSString alloc] initWithUTF8String:nameChars];
            tag.desc = [[NSString alloc] initWithUTF8String:descChars];\
            tag.thumbName = [[NSString alloc] initWithUTF8String:thumbNameChars];
            [tag setAddTimeWithString:[[NSString alloc] initWithUTF8String:addTimeChars]];
            if (collectingItems) {
                tag.itemArray = [self getEmotionItemArrayWithTag:tag.name];
            }
            [result addObject:tag];
        }
        sqlite3_finalize(statement);
    }
    return result;
}

- (NSArray *)getEmotionItemArrayWithTag:(NSString *)tag
{
    NSMutableArray *result = [NSMutableArray new];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE tag LIKE \"%%%@%%\"", kEmotionItemTable, tag];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
        == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *nameChars = (char *) sqlite3_column_text(statement, 1);
            BOOL downloaded = (BOOL) sqlite3_column_text(statement, 2);
            char *series = (char *) sqlite3_column_text(statement, 3);
            char *tags = (char *) sqlite3_column_text(statement, 4);
            KMEmotionItem *eItem = [KMEmotionItem new];
            eItem.imageName = [[NSString alloc] initWithUTF8String:nameChars];
            eItem.isDownloaded = downloaded;
            eItem.series = [[NSString alloc] initWithUTF8String:series];
            NSOrderedSet *orderedSet = [[NSOrderedSet alloc] initWithArray:[[[NSString alloc] initWithUTF8String:tags]componentsSeparatedByString:@","]];
            eItem.tagSet = [[orderedSet set] mutableCopy];
            [result addObject:eItem];
        }
        sqlite3_finalize(statement);
    }
    return result;
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
                tag.itemArray = [self getDownloadedEmotionItemArrayWithTag:tag.name];
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

- (NSArray *)getDownloadedEmotionItemArrayWithTag:(NSString *)tag
{
    if (SQLITE_OK == [self openSharedDb]) {
        NSMutableArray *result = [NSMutableArray new];
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE tag LIKE \"%%%@%%\"", kEmotionItemDownloadedTable, tag];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_shared_database, [query UTF8String], -1, &statement, nil)
            == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *nameChars = (char *) sqlite3_column_text(statement, 1);
                int clickCount = (int) sqlite3_column_text(statement, 2);
                char *series = (char *) sqlite3_column_text(statement, 3);
                char *tags = (char *) sqlite3_column_text(statement, 4);
                KMEmotionItem *eItem = [KMEmotionItem new];
                eItem.imageName = [[NSString alloc] initWithUTF8String:nameChars];
                eItem.clickCount = clickCount;
                eItem.series = [[NSString alloc] initWithUTF8String:series];
                NSOrderedSet *orderedSet = [[NSOrderedSet alloc] initWithArray:[[[NSString alloc] initWithUTF8String:tags]componentsSeparatedByString:@","]];
                eItem.tagSet = [[orderedSet set] mutableCopy];
                [result addObject:eItem];
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

- (void)updateEmotionTag:(KMEmotionTag *)tag
{
    sqlite3_stmt *updateStmt;
    const char *query = "UPDATE emotion_tags SET thumb_name=?, desc=?, downloaded=?, add_time=? where name=?";
    if(sqlite3_prepare_v2(_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
    {
        /*
         * 参数1为query的句柄,
         * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
         * 参数3为参数的值
         * 参数4为值的长度,-1表示以\0为结束符
         * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
         */
        sqlite3_bind_text(updateStmt, 5, [tag.name UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt,  1, [tag.thumbName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [tag.desc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateStmt,  3, 0);
        sqlite3_bind_text(updateStmt, 4, [tag.addTimeString UTF8String], -1, SQLITE_TRANSIENT);
    }
    
    if(SQLITE_DONE != sqlite3_step(updateStmt))
    {
        NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_database));
    }
    
    if (sqlite3_changes(_database) == 0) {
        sqlite3_finalize(updateStmt);
        [self insertEmotionTag:tag];
    }
    else {
        sqlite3_finalize(updateStmt);
    }
}

- (int)insertEmotionTag:(KMEmotionTag *)tag
{
    int rc=0;
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (name, thumb_name, desc, downloaded, add_time) VALUES (\"%@\", \"%@\", \"%@\", %d, \"%@\")", kEmotionTagTable, tag.name, tag.thumbName, tag.desc, 0, tag.addTimeString];
    char *errMsg;
    rc = sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg);
    if(SQLITE_OK != rc)
    {
        NSLog(@"Failed to insert record  rc:%d, msg=%s",rc,errMsg);
    }
    return rc;
}

- (int)updateDownloadedEmotionTag:(KMEmotionTag *)tag
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
        
        if (sqlite3_changes(_shared_database) == 0) {
            sqlite3_finalize(updateStmt);
            [self insertDownloadedEmotionTag:tag];
        }
        else {
            sqlite3_finalize(updateStmt);
        }
        [self closeSharedDb];
        return SQLITE_OK;
    }
    return rc;
}

- (int)insertDownloadedEmotionTag:(KMEmotionTag *)tag
{
    int rc=0;
    if (SQLITE_OK == [self openSharedDb]) {
        NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (name, my_order, thumb_name) VALUES (\"%@\", %d, \"%@\")", kEmotionTagDownloadedTable,
                           tag.name, tag.order, tag.thumbName];
        char *errMsg;
        rc = sqlite3_exec(_shared_database, [query UTF8String], NULL, NULL, &errMsg);
        if(SQLITE_OK != rc)
        {
            NSLog(@"Failed to insert record  rc:%d, msg=%s",rc,errMsg);
        }
        [self closeSharedDb];
    }
    return rc;
}

- (int)deleteDownloadedEmotionTag:(KMEmotionTag *)tag
{
    int rc=0;
    if (SQLITE_OK == [self openSharedDb]) {
        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name=\"%@\"", kEmotionTagDownloadedTable, tag.name];
        char *errMsg;
        rc = sqlite3_exec(_shared_database, [query UTF8String], NULL, NULL, &errMsg);
        if(SQLITE_OK != rc)
        {
            NSLog(@"Failed to delete record:%@, rc:%d, msg=%s",tag,rc,errMsg);
        }
        [self closeSharedDb];
    }
    return rc;
}

- (int)deleteDownloadedEmotionItem:(KMEmotionItem *)item
{
    int rc=0;
    if (SQLITE_OK == [self openSharedDb]) {
        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name=\"%@\"", kEmotionItemDownloadedTable, item.imageName];
        char *errMsg;
        rc = sqlite3_exec(_shared_database, [query UTF8String], NULL, NULL, &errMsg);
        if(SQLITE_OK != rc)
        {
            NSLog(@"Failed to delete record:%@, rc:%d, msg=%s",item,rc,errMsg);
        }
        [self closeSharedDb];
    }
    return rc;
}

- (void)updateEmotionItem:(KMEmotionItem *)item
{
    sqlite3_stmt *updateStmt;
    const char *query = "UPDATE emotion_items SET downloaded=?, series=?, tag=? where name=?";
    if(sqlite3_prepare_v2(_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
    {
        /*
         * 参数1为query的句柄,
         * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
         * 参数3为参数的值
         * 参数4为值的长度,-1表示以\0为结束符
         * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
         */
        sqlite3_bind_text(updateStmt, 4, [item.imageName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateStmt,  1, item.isDownloaded);
        sqlite3_bind_text(updateStmt, 2, [item.series UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [item.tagSetToString UTF8String], -1, SQLITE_TRANSIENT);
    }
    
    if(SQLITE_DONE != sqlite3_step(updateStmt))
    {
        NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_database));
    }
    
    if (sqlite3_changes(_database) == 0) {
        sqlite3_finalize(updateStmt);
        [self insertEmotionItem:item];
    }
    else {
        sqlite3_finalize(updateStmt);
    }
}

- (int)insertEmotionItem:(KMEmotionItem *)item
{
    int rc=0;
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (name, downloaded, series, tag) VALUES (\"%@\", %d, \"%@\", \"%@\")", kEmotionItemTable,
                       item.imageName, item.isDownloaded, item.series, [item tagSetToString]];
    char *errMsg;
    rc = sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg);
    if(SQLITE_OK != rc)
    {
        NSLog(@"Failed to insert record rc:%d, msg=%s",rc,errMsg);
    }
    return rc;
}

- (int)updateDownloadedEmotionItem:(KMEmotionItem *)item
{
    int rc = [self openSharedDb];
    if (rc == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        const char *query = "UPDATE emotion_items_downloaded SET click_times=?, series=?, tag=? where name=?";
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
        
        if (sqlite3_changes(_shared_database) == 0) {
            sqlite3_finalize(updateStmt);
            [self insertDownloadedEmotionItem:item];
        }
        else {
            sqlite3_finalize(updateStmt);
        }
        [self closeSharedDb];
        return SQLITE_OK;
    }
    return rc;
}

- (int)insertDownloadedEmotionItem:(KMEmotionItem *)item
{
    if (![item isDownloaded]) {
        NSLog(@"%s - 逻辑错误!!", __func__);
        assert(0);
        return 1;
    }
    int rc=0;
    if (SQLITE_OK == [self openSharedDb]) {
        NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (name, click_times, series, tag) VALUES (\"%@\", %d, \"%@\", \"%@\")", kEmotionItemDownloadedTable,
                           item.imageName, item.clickCount, item.series, [item tagSetToString]];
        char *errMsg;
        rc = sqlite3_exec(_shared_database, [query UTF8String], NULL, NULL, &errMsg);
        if(SQLITE_OK != rc)
        {
            NSLog(@"Failed to insert record  rc:%d, msg=%s",rc,errMsg);
        }
        [self closeSharedDb];
    }
    return rc;
}

# pragma mark - private method

- (int)openDb
{
    int rc=0;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:[self getDbFilePath]]) {
        [fm createFileAtPath:[self getDbFilePath] contents:nil attributes:nil];
    }
    
    rc = sqlite3_open_v2([[self getDbFilePath] cStringUsingEncoding:NSUTF8StringEncoding], &_database, SQLITE_OPEN_READWRITE, NULL);
    if (SQLITE_OK != rc)
    {
        sqlite3_close(_database);
        NSLog(@"Failed to open db connection");
    }
    return rc;
}

- (int)openSharedDb
{
    int rc=0;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:[self getSharedDbFilePath]]) {
        [fm createFileAtPath:[self getSharedDbFilePath] contents:nil attributes:nil];
    }
    
    rc = sqlite3_open_v2([[self getSharedDbFilePath] cStringUsingEncoding:NSUTF8StringEncoding], &_shared_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != rc)
    {
        sqlite3_close(_shared_database);
        NSLog(@"Failed to open shared db connection");
    }
    return rc;
}

- (void)closeDb
{
    sqlite3_close(_database);
}

- (void)closeSharedDb
{
    sqlite3_close(_shared_database);
}

- (NSString *)getDbFilePath
{
    NSString * docsPath= NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    return [docsPath stringByAppendingPathComponent:kEmotionDatabase];
}

- (NSString *)getSharedDbFilePath
{
    NSString *path = [sharedDirURL.path stringByAppendingPathComponent:kEmotionSharedDatabase];
    
    return path;
}

- (int)createTable
{
    int rc=0;
    char * errMsg;
    
//    NSString *query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, desc text, my_order integer, thumb_name text, tag text, downloaded boolean)", kEmotionSetTable];
//    rc = sqlite3_exec(_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
//    
//    if(SQLITE_OK != rc)
//    {
//        NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionSetTable, rc, errMsg);
//    }
    
    NSString *query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, thumb_name text, desc text, downloaded boolean, add_time DATETIME)", kEmotionTagTable];
    rc = sqlite3_exec(_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
    if(SQLITE_OK != rc) {
        NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionTagTable, rc, errMsg);
    }
    
    query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, downloaded boolean, series text, tag text)", kEmotionItemTable];
    rc = sqlite3_exec(_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
    
    if(SQLITE_OK != rc)
    {
        NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionItemTable, rc, errMsg);
    }
    
    if (SQLITE_OK == [self openSharedDb]) {
        
//        query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, desc text, my_order integer, thumb_name text, tag text)", kEmotionSetDownloadedTable];
//        rc = sqlite3_exec(_shared_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
//        if (SQLITE_OK != rc) {
//            NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionSetDownloadedTable, rc, errMsg);
//        }
        
        query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, my_order integer, thumb_name text)", kEmotionTagDownloadedTable];
        rc = sqlite3_exec(_shared_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
        if(SQLITE_OK != rc) {
            NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionTagDownloadedTable, rc, errMsg);
        }
        
        query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, name text, click_times integer, series text, tag text)", kEmotionItemDownloadedTable];
        rc = sqlite3_exec(_shared_database, [query cStringUsingEncoding:NSUTF8StringEncoding],NULL,NULL,&errMsg);
        if (SQLITE_OK != rc) {
            NSLog(@"Failed to create table %@, rc:%d, msg=%s", kEmotionItemDownloadedTable, rc, errMsg);
        }
        [self closeSharedDb];
    }
    
    return rc;
}

//- (int)addEmotionSet:(KMEmotionSet *)set
//{
//    int rc=0;
//    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (name, desc, my_order, thumb_name, tag, downloaded) VALUES (\"%@\", \"%@\", %d, \"%@\", \"%@\", %d)", kEmotionSetTable,
//                       set.name, set.desc, (int)set.order, set.thumbName, set.tag, set.isDownloaded];
//    char *errMsg;
//    rc = sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg);
//    if(SQLITE_OK != rc)
//    {
//        NSLog(@"Failed to insert record  rc:%d, msg=%s",rc,errMsg);
//    }
//    return rc;
//}
//
//- (int)deleteDownloadedEmotionSet:(KMEmotionSet *)set
//{
//    if (![set isDownloaded]) {
//        NSLog(@"%s - 逻辑错误!!", __func__);
//        assert(0);
//        return 1;
//    }
//    int rc=0;
//    if (SQLITE_OK == [self openSharedDb]) {
//        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name=\"%@\"", kEmotionSetDownloadedTable,
//                           set.name];
//        char *errMsg;
//        rc = sqlite3_exec(_shared_database, [query UTF8String], NULL, NULL, &errMsg);
//        if(SQLITE_OK != rc)
//        {
//            NSLog(@"Failed to delete record  rc:%d, msg=%s",rc,errMsg);
//        }
//        [self closeSharedDb];
//    }
//    return rc;
//}
//
//- (NSArray *)getEmotionSetArray
//{
//    NSMutableArray *result = [NSMutableArray new];
//    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY my_order", kEmotionSetTable];
//    sqlite3_stmt *statement;
//    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
//        == SQLITE_OK) {
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            char *nameChars = (char *) sqlite3_column_text(statement, 1);
//            char *descChars = (char *) sqlite3_column_text(statement, 2);
//            int order = sqlite3_column_int(statement, 3);
//            char *thumbNameChars = (char *) sqlite3_column_text(statement, 4);
//            char *tagChars = (char *) sqlite3_column_text(statement, 5);
//            BOOL isDownloaded = sqlite3_column_int(statement, 6);
//            KMEmotionSet *eSet = [KMEmotionSet new];
//            eSet.name = [[NSString alloc] initWithUTF8String:nameChars];
//            eSet.desc = [[NSString alloc] initWithUTF8String:descChars];
//            eSet.order = order;
//            eSet.thumbName = [[NSString alloc] initWithUTF8String:thumbNameChars];
//            eSet.tag = [[NSString alloc] initWithUTF8String:tagChars];
//            eSet.itemArray = [self getEmotionItemArrayWithSeries:eSet.name];
//            eSet.isDownloaded = isDownloaded;
//            [result addObject:eSet];
//        }
//        sqlite3_finalize(statement);
//    }
//    return result;
//}
//
//- (NSArray *)getDownloadedEmotionSetArray
//{
//    if (SQLITE_OK == [self openSharedDb]) {
//        NSMutableArray *result = [NSMutableArray new];
//        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY my_order", kEmotionSetDownloadedTable];
//        sqlite3_stmt *statement;
//        if (sqlite3_prepare_v2(_shared_database, [query UTF8String], -1, &statement, nil)
//            == SQLITE_OK) {
//            while (sqlite3_step(statement) == SQLITE_ROW) {
//                char *nameChars = (char *) sqlite3_column_text(statement, 1);
//                char *descChars = (char *) sqlite3_column_text(statement, 2);
//                int order = sqlite3_column_int(statement, 3);
//                char *thumbNameChars = (char *) sqlite3_column_text(statement, 4);
//                char *tagChars = (char *) sqlite3_column_text(statement, 5);
//                KMEmotionSet *eSet = [KMEmotionSet new];
//                eSet.name = [[NSString alloc] initWithUTF8String:nameChars];
//                eSet.desc = [[NSString alloc] initWithUTF8String:descChars];
//                eSet.order = order;
//                eSet.thumbName = [[NSString alloc] initWithUTF8String:thumbNameChars];
//                eSet.tag = [[NSString alloc] initWithUTF8String:tagChars];
//                eSet.itemArray = [self getEmotionItemArrayWithSeries:eSet.name];
//                eSet.isDownloaded = YES;
//                [result addObject:eSet];
//            }
//            sqlite3_finalize(statement);
//        }
//        [self closeSharedDb];
//        return result;
//    }
//    else
//    {
//        return nil;
//    }
//}
//
//- (NSMutableArray *)getEmotionItemArrayWithSeries:(NSString *)series
//{
//    NSMutableArray *result = [NSMutableArray new];
//    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE series = \"%@\"", kEmotionItemTable, series];
//    sqlite3_stmt *statement;
//    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil)
//        == SQLITE_OK) {
//        while (sqlite3_step(statement) == SQLITE_ROW) {
//            char *nameChars = (char *) sqlite3_column_text(statement, 1);
//            BOOL downloaded = (BOOL) sqlite3_column_text(statement, 2);
//            char *series = (char *) sqlite3_column_text(statement, 3);
//            char *tags = (char *) sqlite3_column_text(statement, 4);
//            KMEmotionItem *eItem = [KMEmotionItem new];
//            eItem.imageName = [[NSString alloc] initWithUTF8String:nameChars];
//            eItem.isDownloaded = downloaded;
//            eItem.series = [[NSString alloc] initWithUTF8String:series];
//            NSOrderedSet *orderedSet = [[NSOrderedSet alloc] initWithArray:[[[NSString alloc] initWithUTF8String:tags]componentsSeparatedByString:@","]];
//            eItem.tagSet = [orderedSet set];
//            [result addObject:eItem];
//        }
//        sqlite3_finalize(statement);
//    }
//    return result;
//    
//}
//
//- (void)updateEmotionSet:(KMEmotionSet *)set
//{
//    sqlite3_stmt *updateStmt;
//    const char *query = "UPDATE emotion_series SET desc=?, my_order=?, thumb_name=?, tag=?, downloaded=? where name=?";
//    if(sqlite3_prepare_v2(_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
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
//        NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_database));
//    }
//    sqlite3_finalize(updateStmt);
//}
//
//- (int)updateDownloadedEmotionSet:(KMEmotionSet *)set
//{
//    int rc = [self openSharedDb];
//    if (rc == SQLITE_OK) {
//        sqlite3_stmt *updateStmt;
//        const char *query = "UPDATE emotion_series_downloaded SET desc=?, my_order=?, thumb_name=?, tag=? WHERE name=?";
//        if(sqlite3_prepare_v2(_shared_database, query, -1, &updateStmt, NULL) == SQLITE_OK)
//        {
//            /*
//             * 参数1为query的句柄,
//             * 参数2为要绑定的参数的索引,第一个为1,如有重复使用参数都使用同一索引
//             * 参数3为参数的值
//             * 参数4为值的长度,-1表示以\0为结束符
//             * 参数5 SQLITE_TRANSIENT表示传入的值有可能被改变,需要sqlite保留一份值的副本
//             */
//            sqlite3_bind_text(updateStmt, 5, [set.name UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(updateStmt, 1, [set.desc UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_int(updateStmt,  2, (int)set.order);
//            sqlite3_bind_text(updateStmt, 3, [set.thumbName UTF8String], -1, SQLITE_TRANSIENT);
//            sqlite3_bind_text(updateStmt, 4, [set.tag UTF8String], -1, SQLITE_TRANSIENT);
//        }
//        
//        if(SQLITE_DONE != sqlite3_step(updateStmt))
//        {
//            NSLog(@"%s - Error while updating. %s", __func__, sqlite3_errmsg(_shared_database));
//        }
//        sqlite3_finalize(updateStmt);
//        [self closeSharedDb];
//        return SQLITE_OK;
//    }
//    else
//    {
//        return rc;
//    }
//    
//}

@end
