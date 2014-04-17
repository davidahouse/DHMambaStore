//
//  MambaStore.h
//  
//
//  Created by David House on 9/27/13.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "NSObject+MambaObject.h"

@class MambaDocument;

static NSString *const kMambaStoreNotification = @"MambaStoreNotification";

@interface MambaStore : NSObject

#pragma mark - Open/Close Methods
+ (void)openStore;
+ (void)openStore:(NSString *)storeName;
+ (void)openStoreWithPath:(NSString *)storePath;
+ (void)closeStore;
+ (void)removeStore;
+ (void)removeStore:(NSString *)storeName;
+ (void)removeStoreWithPath:(NSString *)storePath;

#pragma mark - Collection methods
+ (void)emptyCollection:(NSString *)collection;
+ (void)insertObject:(id)object;
+ (void)updateObject:(id)object;
+ (void)deleteObject:(id)object;

#pragma mark - Query methods
+ (void)selectFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters order:(MambaObjectOrderBy)orderBy limit:(NSUInteger)limit resultBlock:(void (^)(FMResultSet *results))resultBlock;
+ (NSNumber *)countFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters;

@end
