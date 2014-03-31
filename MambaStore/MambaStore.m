//
//  MambaStore.m
//  
//
//  Created by David House on 9/27/13.
//
//

#import "MambaStore.h"
#import "FMDatabaseQueue.h"

static FMDatabaseQueue *staticStore;
static NSMutableArray *staticCollectionList;
static NSMutableDictionary *staticCollectionSources;

@implementation MambaStore

#pragma mark - Open/Close Methods

+ (void)openStore {
    
    [MambaStore openStore:@"mamba.db"];
}

+ (void)openStore:(NSString *)storeName {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:storeName];
    [MambaStore openStoreWithPath:fullPath];
}

+ (void)openStoreWithPath:(NSString *)storePath {
    
    if ( staticStore ) {
        [MambaStore closeStore];
    }
    
    NSLog(@"opening store at path: %@",storePath);
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
    
    [MambaStore removeStore:@"mamba.db"];
}

+ (void)removeStore:(NSString *)storeName {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:storeName];
    [MambaStore removeStoreWithPath:fullPath];
}

+ (void)removeStoreWithPath:(NSString *)storePath {
    
    if ( staticStore ) {
        [MambaStore closeStore];
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
    
    NSString *collection = NSStringFromClass([object class]);
    [MambaStore createCollectionIfDoesntExist:[object class]];

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
        [[NSNotificationCenter defaultCenter] postNotificationName:kMambaStoreNotification object:[object class] userInfo:@{@"operation":@"insert",@"object":objID}];
    }];
}

+ (void)updateObject:(id)object {
    
    NSString *collection = NSStringFromClass([object class]);
    [MambaStore createCollectionIfDoesntExist:[object class]];
    
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
        [[NSNotificationCenter defaultCenter] postNotificationName:kMambaStoreNotification object:[object class] userInfo:@{@"operation":@"update",@"object":objID}];
    }];
    
}

+ (void)deleteObject:(id)object {
    
    NSString *collection = NSStringFromClass([object class]);
    [MambaStore createCollectionIfDoesntExist:[object class]];
    
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kMambaStoreNotification object:[object class] userInfo:@{@"operation":@"delete",@"object":objID}];
        }];
    }
}

#pragma mark - Query methods
+ (FMResultSet *)selectFromCollection:(NSString *)collection where:(NSString *)whereClause order:(NSString *)orderBy limit:(int)limit {
    
    NSString *querySql =[NSString stringWithFormat:@"select * from %@",collection];
    if ( ![whereClause isEqualToString:@""] ) {
        querySql = [querySql stringByAppendingFormat:@" where %@",whereClause];
    }
    
    if ( orderBy && ![orderBy isEqualToString:@""] ) {
        querySql = [querySql stringByAppendingFormat:@" order by %@",orderBy];
    }
    
    if ( limit > 0 ) {
        querySql = [querySql stringByAppendingFormat:@" limit %d",limit];
    }
    
    NSLog(@"MAMBASTORE## query: %@",querySql);
    __block FMResultSet *results = nil;
    [staticStore inDatabase:^(FMDatabase *db) {

        results = [db executeQuery:querySql];
    }];
    return results;
}

#pragma mark - Private Methods
+ (void)createCollectionIfDoesntExist:(Class)docClass{
    
    NSString *collection = NSStringFromClass(docClass);
    
    // Check for the static array that lists all the collections
    if ( !staticCollectionList ) {
        staticCollectionList = [[NSMutableArray alloc] init];
    }
    
    // Now check if we have already created this collection, if so
    // just return as there is nothing to do.
    if ( ![staticCollectionList containsObject:collection] ) {
        
        // create a table for this collection
        NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@ (objID text, objKey text, objForeignKey text, objTitle text, createTime real, updateTime real, orderNumber integer, objBody blob)",collection];
        NSLog(@"createSQL: %@",createSQL);
        [staticStore inDatabase:^(FMDatabase *db) {

            if ( ![db executeUpdate:createSQL] ) {
                NSLog(@"error creating table: %@",[db lastErrorMessage]);
            }

        }];
        
        [staticCollectionList addObject:collection];
        
        // Also create a dispatch source so we have somewhere to post
        // any updates to the collection
        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
        dispatch_resume(source);
    }
}


@end
