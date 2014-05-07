//
//  DHMambaStore.h
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

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "NSObject+DHMambaObject.h"

static NSString *const kDHMambaStoreNotification = @"DHMambaStoreNotification";

@interface DHMambaStore : NSObject

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
+ (void)selectFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters order:(DHMambaObjectOrderBy)orderBy limit:(NSUInteger)limit resultBlock:(void (^)(FMResultSet *results))resultBlock;
+ (NSNumber *)countFromCollection:(NSString *)collection where:(NSString *)whereClause parameters:(NSDictionary *)parameters;

@end
