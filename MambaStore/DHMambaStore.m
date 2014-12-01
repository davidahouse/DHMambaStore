//
//  MambaStore.m
//  
//
//  Created by David House on 9/27/13.
//  Copyright (c) 2014 David House <davidahouse@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "DHMambaStore.h"
#import "FMDatabaseQueue.h"

static FMDatabaseQueue *staticStore;
static NSMutableArray *staticCollectionList;
static NSMutableDictionary *staticCollectionSources;

@implementation DHMambaStore

#pragma mark - Open/Close Methods

+ (void)openStore {
    
    [DHMambaStore openStore:@"mamba.db"];
}

+ (void)openStore:(NSString *)storeName {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:storeName];
    [DHMambaStore openStoreWithPath:fullPath];
}

+ (void)openStoreWithPath:(NSString *)storePath {
    
    if ( staticStore ) {
        [DHMambaStore closeStore];
    }
    
    // NSLog(@"opening store at path: %@",storePath);
    staticStore = [FMDatabaseQueue databaseQueueWithPath:storePath];
}

+ (void)closeStore {
    
    [staticStore close];
    staticStore = nil;
    if ( staticCollectionList ) {
        [staticCollectionList removeAllObjects];
    }
    if ( staticCollectionSources ) {
        
        for ( id key in staticCollectionSources ) {
            dispatch_source_t source = (dispatch_source_t)[staticCollectionSources valueForKey:key];
            dispatch_source_cancel(source);
        }
        [staticCollectionSources removeAllObjects];
    }
}

+ (void)removeStore {
    
    [DHMambaStore removeStore:@"mamba.db"];
}

+ (void)removeStore:(NSString *)storeName {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:storeName];
    [DHMambaStore removeStoreWithPath:fullPath];
}

+ (void)removeStoreWithPath:(NSString *)storePath {
    
    if ( staticStore ) {
        [DHMambaStore closeStore];
    }
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:storePath error:&error];
}


#pragma mark - Collection methods

+ (void)emptyCollection:(NSString *)collection {
    
    [staticStore inDatabase:^(FMDatabase *db) {
        if ( ![db executeUpdate:[NSString stringWithFormat:@"delete from %@",collection]] ) {
            NSLog(@"error emptying collection: %@",[db lastErrorMessage]);
        }
    }];
}

+ (void)insertObject:(id)object {
    
    NSString *collection = [NSStringFromClass([object class]) stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    [DHMambaStore createCollectionIfDoesntExist:[object class]];

    NSString *objID = [object MB_objID];
    NSString *objKey = [object MB_objKey];
    NSString *objForeignKey = [object MB_objForeignKey];
    NSString *objTitle = [object MB_objTitle];
    NSNumber *objOrderNumber = [object MB_objOrderNumber];
    NSData *objData = [object MB_objData];

    NSString *insertSQL = [NSString stringWithFormat:@"insert into %@ VALUES ( :objID, :objKey, :objForeignKey, :objTitle, :createTime, :updateTime, :orderNumber, :objBody )",collection];
    
    [staticStore inDatabase:^(FMDatabase *db) {
        
        NSDictionary *parameters = @{ @"objID": objID,
                                      @"objKey": objKey ? objKey : [NSNull null],
                                      @"objForeignKey" : objForeignKey ? objForeignKey : [NSNull null],
                                      @"objTitle": objTitle ? objTitle : [NSNull null],
                                      @"createTime":[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                                      @"updateTime":[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                                      @"orderNumber": objOrderNumber ? objOrderNumber : [NSNull null],
                                      @"objBody": objData };
        
        if ( ![db executeUpdate:insertSQL withParameterDictionary:parameters]) {
            
            NSLog(@"error inserting data: %@",[db lastErrorMessage]);
        }
        
        // Post a notification so listeners can catch inserts
        // in other parts of the code.
        [[NSNotificationCenter defaultCenter] postNotificationName:kDHMambaStoreNotification object:[object class] userInfo:@{@"operation":@"insert",@"object":objID}];
    }];
}

+ (void)updateObject:(id)object {
    
    NSString *collection = [NSStringFromClass([object class]) stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    [DHMambaStore createCollectionIfDoesntExist:[object class]];
    
    NSString *objID = [object MB_objID];
    NSString *objKey = [object MB_objKey];
    NSString *objForeignKey = [object MB_objForeignKey];
    NSString *objTitle = [object MB_objTitle];
    NSNumber *objOrderNumber = [object MB_objOrderNumber];
    NSData *objData = [object MB_objData];
    
    NSString *updateSql = [NSString stringWithFormat:@"update %@ set objKey = :objKey, objForeignKey = :objForeignKey, objTitle = :objTitle, orderNumber = :orderNumber, updateTime = :updateTime, objBody = :objBody where objID = :objID",collection];
    
    [staticStore inDatabase:^(FMDatabase *db) {
        
        NSDictionary *parameters = @{ @"objID": objID,
                                      @"objKey": objKey ? objKey : [NSNull null],
                                      @"objForeignKey" : objForeignKey ? objForeignKey : [NSNull null],
                                      @"objTitle": objTitle ? objTitle : [NSNull null],
                                      @"updateTime":[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                                      @"orderNumber": objOrderNumber ? objOrderNumber : [NSNull null],
                                      @"objBody": objData };
        
        if ( ![db executeUpdate:updateSql withParameterDictionary:parameters] ) {
            NSLog(@"error updating data: %@",[db lastErrorMessage]);
        }
        
        // Post a notification so listeners can catch inserts
        // in other parts of the code.
        [[NSNotificationCenter defaultCenter] postNotificationName:kDHMambaStoreNotification object:[object class] userInfo:@{@"operation":@"update",@"object":objID}];
    }];
    
}

+ (void)deleteObject:(id)object {
    
    NSString *collection = [NSStringFromClass([object class]) stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    [DHMambaStore createCollectionIfDoesntExist:[object class]];
    
    // If no id, then just ignore since this object hasn't been stored yet
    if ( [object MB_has_objID] ) {
        NSString *objID = [object MB_objID];
        
        NSString *sql = [NSString stringWithFormat:@"delete from %@ where objID = :objID",collection];
        [staticStore inDatabase:^(FMDatabase *db) {
            
            if ( ![db executeUpdate:sql withParameterDictionary:@{@"objID":objID}]) {
                NSLog(@"error deleting data: %@",[db lastErrorMessage]);
            }
            
            // Post a notification so listeners can catch inserts
            // in other parts of the code.
            [[NSNotificationCenter defaultCenter] postNotificationName:kDHMambaStoreNotification object:[object class] userInfo:@{@"operation":@"delete",@"object":objID}];
        }];
    }
}

#pragma mark - Query methods
+ (void)selectFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters order:(DHMambaObjectOrderBy)orderBy limit:(NSUInteger)limit resultBlock:(void (^)(FMResultSet *))resultBlock {
    
    if ( !resultBlock ) {
        NSLog(@"Error: no result block passed in, so pointless to run the query.");
        return;
    }
    
    NSString *querySql =[NSString stringWithFormat:@"select * from %@",collection];
    if ( ![whereClause isEqualToString:@""] ) {
        querySql = [querySql stringByAppendingFormat:@" where %@",whereClause];
    }
    
    NSString *orderByString = @"";
    switch ( orderBy ) {
    case DHMambaObjectOrderByKey:
        orderByString = @"objKey";
        break;
    case DHMambaObjectOrderByTitle:
        orderByString = @"objTitle";
        break;
    case DHMambaObjectOrderByForeignKey:
        orderByString = @"objForeignKey";
        break;
    case DHMambaObjectOrderByCreateTime:
        orderByString = @"createTime";
        break;
    case DHMambaObjectOrderByUpdateTime:
        orderByString = @"updateTime";
        break;
    case DHMambaObjectOrderByOrderNumber:
        orderByString = @"orderNumber";
        break;
    case DHMambaObjectOrderByKeyDescending:
        orderByString = @"objKey DESC";
        break;
    case DHMambaObjectOrderByTitleDescending:
        orderByString = @"objTitle DESC";
        break;
    case DHMambaObjectOrderByForeignKeyDescending:
        orderByString = @"objForeignKey DESC";
        break;
    case DHMambaObjectOrderByCreateTimeDescending:
        orderByString = @"createTime DESC";
        break;
    case DHMambaObjectOrderByUpdateTimeDescending:
        orderByString = @"updateTime DESC";
        break;
    case DHMambaObjectOrderByOrderNumberDescending:
        orderByString = @"orderNumber DESC";
        break;
    }

    querySql = [querySql stringByAppendingFormat:@" order by %@",orderByString];
    
    if ( limit > 0 ) {
        querySql = [querySql stringByAppendingFormat:@" limit %lu",(unsigned long)limit];
    }
    
    // NSLog(@"MAMBASTORE## query: %@",querySql);
    __block FMResultSet *results = nil;
    [staticStore inDatabase:^(FMDatabase *db) {

        results = [db executeQuery:querySql withParameterDictionary:parameters];
        while ( [results next] ) {
            resultBlock(results);
        }
    }];
}

+ (NSNumber *)countFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters
{
    NSString *querySql = [NSString stringWithFormat:@"select count(*) from %@",collection];
    if ( ![whereClause isEqualToString:@""] ) {
        querySql = [querySql stringByAppendingFormat:@" where %@",whereClause];
    }
    
    // NSLog(@"MAMBASTORE## query: %@",querySql);
    __block NSNumber *count = @0;
    [staticStore inDatabase:^(FMDatabase *db) {
        
        FMResultSet *results = [db executeQuery:querySql withParameterDictionary:parameters];
        if ( [results next] ) {
            count = [NSNumber numberWithInt:[results intForColumnIndex:0]];
        }
        [results close];
    }];
    return count;
}

#pragma mark - Private Methods
+ (void)createCollectionIfDoesntExist:(Class)docClass{
    
    NSString *collection = [NSStringFromClass(docClass) stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    
    // Check for the static array that lists all the collections
    if ( !staticCollectionList ) {
        staticCollectionList = [[NSMutableArray alloc] init];
    }
    
    // Now check if we have already created this collection, if so
    // just return as there is nothing to do.
    if ( ![staticCollectionList containsObject:collection] ) {
        
        // create a table for this collection
        NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@ (objID text, objKey text, objForeignKey text, objTitle text, createTime real, updateTime real, orderNumber integer, objBody blob)",collection];
        // NSLog(@"createSQL: %@",createSQL);
        
        NSString *createPKIndexSQL = [NSString stringWithFormat:@"create index if not exists %@_pk ON %@ (objID)",collection,collection];

        NSString *createKeyIndexSQL = [NSString stringWithFormat:@"create index if not exists %@_pk ON %@ (objKey)",collection,collection];

        [staticStore inDatabase:^(FMDatabase *db) {

            if ( ![db executeUpdate:createSQL] ) {
                NSLog(@"error creating table: %@",[db lastErrorMessage]);
            }

            if ( ![db executeUpdate:createPKIndexSQL] ) {
                NSLog(@"error creating PK index: %@",[db lastErrorMessage]);
            }

            if ( ![db executeUpdate:createKeyIndexSQL] ) {
                NSLog(@"error creating Key index: %@",[db lastErrorMessage]);
            }
        }];
        
        [staticCollectionList addObject:collection];
    }
}


@end
