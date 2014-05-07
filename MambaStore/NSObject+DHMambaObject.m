//
//  NSObject+DHMambaObject.m
//  
//
//  Created by David House on 1/23/14.
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

#import "NSObject+DHMambaObject.h"
#import "DHMambaStore.h"
#import <Objc/runtime.h>

//
// Static constants used in the associated objects
//
static char const * const DHMambaObjectIDKey = "MambaObjectID";
static char const * const DHMambaObjectCreateTimeKey = "MambaObjectCreateTime";
static char const * const DHMambaObjectUpdateTimeKey = "MambaObjectUpdateTime";

@implementation NSObject (DHMambaObject)


#pragma mark - Convenience methods for getting & setting mamba specific properties
- (BOOL)MB_has_objID {

    if ( objc_getAssociatedObject(self, DHMambaObjectIDKey) ) {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSString *)MB_objID {
    
    // Look in associated object storage for the object ID. If not found, we need to create one!
    if ( [self MB_has_objID] ) {
        NSString *objID = objc_getAssociatedObject(self, DHMambaObjectIDKey);
        return objID;
    }
    else {
        NSString *objID = [[NSUUID UUID] UUIDString];
        objc_setAssociatedObject(self, DHMambaObjectIDKey, objID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return objID;
    }
}

- (NSString *)MB_objKey {
    
    // See if the object supports custom object keys. If not, we use the objID instead
    if ( [self respondsToSelector:@selector(mambaObjectKey)] ) {
        return [self performSelector:@selector(mambaObjectKey)];
    }
    else {
        return [self MB_objID];
    }
}

- (NSString *)MB_objForeignKey {

    // Return foreign key or nil
    if ( [self respondsToSelector:@selector(mambaObjectForeignKey)] ) {
        return [self performSelector:@selector(mambaObjectForeignKey)];
    }
    else {
        return nil;
    }
}

- (NSString *)MB_objTitle {

    // Return foreign key or nil
    if ( [self respondsToSelector:@selector(mambaObjectTitle)] ) {
        return [self performSelector:@selector(mambaObjectTitle)];
    }
    else {
        return nil;
    }
}

- (NSNumber *)MB_objOrderNumber {
    
    // Return foreign key or nil
    if ( [self respondsToSelector:@selector(mambaObjectOrderNumber)] ) {
        return [self performSelector:@selector(mambaObjectOrderNumber)];
    }
    else {
        return nil;
    }
}

- (NSData *)MB_objData {
    
    // If object handles its own NSCoding, let it! Otherwise, its
    // ours.
    if ( [self conformsToProtocol:@protocol(NSCoding)] ) {
        
        NSData *bodyArchive = [NSKeyedArchiver archivedDataWithRootObject:self];
        return bodyArchive;
    }
    else {
    
        // Object data is actually an NSCoded version of the object, aquired automatically by inspecting the class to
        // see which properties exist and have backing iVars. We also cache this knowledge so we only have to do it once
        // per class.
        NSArray *properties = [self MB_class_propertyNames];

        // See if the object has any properties that we should not encode
        NSArray *ignoreList = nil;
        if ( [self respondsToSelector:@selector(mambaObjectIgnoreProperties)] ) {
            ignoreList = [self performSelector:@selector(mambaObjectIgnoreProperties)];
        }

        // Archive it baby!
        NSMutableData *bodyArchive = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:bodyArchive];
        for ( NSString *property in properties ) {
        
            // exclude child collections
            if ( !ignoreList || ![ignoreList containsObject:property] ) {
                [archiver encodeObject:[self valueForKey:property] forKey:property];
            }
        }
        [archiver finishEncoding];
        return bodyArchive;
    }
}

- (NSDate *)MB_createTime {
    
    // Look in associated object storage. If not found, we need to create one!
    if ( objc_getAssociatedObject(self, DHMambaObjectCreateTimeKey) ) {

        NSDate *createTime = objc_getAssociatedObject(self, DHMambaObjectCreateTimeKey);
        return createTime;
    }
    else {
        return nil;
    }
}

- (NSDate *)MB_updateTime {
    
    // Look in associated object storage. If not found, we need to create one!
    if ( objc_getAssociatedObject(self, DHMambaObjectCreateTimeKey) ) {
        
        NSDate *updateTime = objc_getAssociatedObject(self, DHMambaObjectUpdateTimeKey);
        return updateTime;
    }
    else {
        return nil;
    }
}


#pragma mark - CRUD methods
- (void)MB_save {
    
    // if this object hasn't been in the store yet, we
    // need to insert it, otherwise update it.
    if ( ![self MB_has_objID] ) {
        [DHMambaStore insertObject:self];
    }
    else {
        [DHMambaStore updateObject:self];
    }
    
    if ( [self respondsToSelector:@selector(mambaAfterSave)] ) {
        [self performSelector:@selector(mambaAfterSave)];
    }
}

- (void)MB_delete {
    
    [DHMambaStore deleteObject:self];

    if ( [self respondsToSelector:@selector(mambaAfterDelete)] ) {
        [self performSelector:@selector(mambaAfterDelete)];
    }
}

- (void)MB_deleteAll {
    
    NSString *collection = NSStringFromClass([self class]);
    [DHMambaStore emptyCollection:collection];
}

#pragma mark - Search methods
+ (id)MB_loadWithID:(NSString *)objectID
{
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block id resultObject = nil;
    [DHMambaStore selectFromCollection:collection where:@"objID = :objID" parameters:@{@"objID":objectID} order:DHMambaObjectOrderByOrderNumber limit:0 resultBlock:^(FMResultSet *results) {
        
        resultObject = [self MB_unarchive_withResults:results];
    }];
    [self MB_performAfterLoad:resultObject];
    return resultObject;
}

+ (id)MB_findWithKey:(NSString *)key {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block id resultObject = nil;
    [DHMambaStore selectFromCollection:collection where:@"objKey = :objKey" parameters:@{@"objKey":key} order:DHMambaObjectOrderByOrderNumber limit:0 resultBlock:^(FMResultSet *results) {
        
        resultObject = [self MB_unarchive_withResults:results];
    }];
    [self MB_performAfterLoad:resultObject];
    return resultObject;
}

+ (NSArray *)MB_findAll
{
    return [self MB_findAllLimit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findAllLimit:(NSUInteger)limit
{
    return [self MB_findAllLimit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findAllOrderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findAllLimit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findAllLimit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[] parameters:@{} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findInKey:(NSString *)key
{
    return [self MB_findInKey:key limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit
{
    return [self MB_findInKey:key limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInKey:(NSString *)key orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findInKey:key limit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"objKey like :objKey"] parameters:@{@"objKey":[NSString stringWithFormat:@"%%%@%%",key]} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findWithTitle:(NSString *)title
{
    return [self MB_findWithTitle:title limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit
{
    return [self MB_findWithTitle:title limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithTitle:(NSString *)title orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findWithTitle:title limit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"objTitle = :objTitle"] parameters:@{@"objTitle":title} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findInTitle:(NSString *)title
{
    return [self MB_findInTitle:title limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit
{
    return [self MB_findInTitle:title limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInTitle:(NSString *)title orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findInTitle:title limit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"objTitle like :objTitle"] parameters:@{@"objTitle":[NSString stringWithFormat:@"%%%@%%",title]} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey
{
    return [self MB_findWithForeignKey:foreignKey limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit
{
    return [self MB_findWithForeignKey:foreignKey limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findWithForeignKey:foreignKey limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"objForeignKey = :objForeignKey"] parameters:@{@"objForeignKey":foreignKey} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey
{
    return [self MB_findInForeignKey:foreignKey limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit
{
    return [self MB_findInForeignKey:foreignKey limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findInForeignKey:foreignKey limit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"objForeignKey like :objForeignKey"] parameters:@{@"objForeignKey":[NSString stringWithFormat:@"%%%@%%",foreignKey]} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to
{
    return [self MB_findWithOrderNumberFrom:from to:to limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit
{
    return [self MB_findWithOrderNumberFrom:from to:to limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_findWithOrderNumberFrom:from to:to limit:0 orderBy:orderBy];
}

+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy
{
    return [self MB_search:@[@"orderNumber >= :fromOrderNumber",@"orderNumber <= :toOrderNumber"] parameters:@{@"fromOrderNumber":from,@"toOrderNumber":to} limit:limit orderBy:orderBy];
}

+ (NSArray *)MB_createdMostRecent:(NSUInteger)top
{
    return [self MB_search:@[] parameters:@{} limit:top orderBy:DHMambaObjectOrderByCreateTimeDescending];
}

+ (NSArray *)MB_createdLeastRecent:(NSUInteger)top
{
    return [self MB_search:@[] parameters:@{} limit:top orderBy:DHMambaObjectOrderByCreateTime];
}

+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to
{
    return [self MB_search:@[@"createTime >= :fromTime",@"createTime <= :toTime"] parameters:@{@"fromTime":from,@"toTime":to} limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit
{
    return [self MB_search:@[@"createTime >= :fromTime",@"createTime <= :toTime"] parameters:@{@"fromTime":from,@"toTime":to} limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_updatedMostRecent:(NSUInteger)top
{
    return [self MB_search:@[] parameters:@{} limit:top orderBy:DHMambaObjectOrderByUpdateTimeDescending];
}

+ (NSArray *)MB_updatedLeastRecent:(NSUInteger)top
{
    return [self MB_search:@[] parameters:@{} limit:top orderBy:DHMambaObjectOrderByUpdateTime];
}

+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to
{
    return [self MB_search:@[@"updateTime >= :fromTime",@"updateTime <= :toTime"] parameters:@{@"fromTime":from,@"toTime":to} limit:0 orderBy:DHMambaObjectOrderByOrderNumber];
}

+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit
{
    return [self MB_search:@[@"updateTime >= :fromTime",@"updateTime <= :toTime"] parameters:@{@"fromTime":from,@"toTime":to} limit:limit orderBy:DHMambaObjectOrderByOrderNumber];
}


#pragma mark - Count Methods

+ (NSNumber *)MB_countAll
{
    return [self MB_count:@"" parameters:@{}];
}

+ (NSNumber *)MB_countWithKey:(NSString *)key
{
    return [self MB_count:@"objKey = :objKey" parameters:@{@"objKey":key}];
}

+ (NSNumber *)MB_countLikeKey:(NSString *)key
{
    return [self MB_count:@"objKey like :objKey" parameters:@{@"objKey":[NSString stringWithFormat:@"%%%@%%",key]}];
}

+ (NSNumber *)MB_countWithTitle:(NSString *)title
{
    return [self MB_count:@"objTitle = :objTitle" parameters:@{@"objTitle":title}];
}

+ (NSNumber *)MB_countLikeTitle:(NSString *)title
{
    return [self MB_count:@"objTitle like :objTitle" parameters:@{@"objTitle":[NSString stringWithFormat:@"%%%@%%",title]}];
}

+ (NSNumber *)MB_countWithForeignKey:(NSString *)foreignKey
{
    return [self MB_count:@"objForeignKey = :objForeignKey" parameters:@{@"objForeignKey":foreignKey}];
}

+ (NSNumber *)MB_countLikeForeignKey:(NSString *)foreignKey
{
    return [self MB_count:@"objForeignKey like :objForeignKey" parameters:@{@"objForeignKey":[NSString stringWithFormat:@"%%%@%%",foreignKey]}];
}

+ (NSNumber *)MB_countOrderedFrom:(NSNumber *)fromOrderNumber to:(NSNumber *)toOrderNumber
{
    return [self MB_count:@"orderNumber >= :fromOrderNumber and orderNumber <= :toOrderNumber" parameters:@{@"fromOrderNumber":fromOrderNumber,@"toOrderNumber":toOrderNumber}];
}

+ (NSNumber *)MB_countCreatedFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    return [self MB_count:@"createTime >= :fromDate and createTime <= :toDate" parameters:@{@"fromDate":fromDate,@"toDate":toDate}];
}

+ (NSNumber *)MB_countUpdatedFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    return [self MB_count:@"updateTime >= :fromDate and updateTime <= :toDate" parameters:@{@"fromDate":fromDate,@"toDate":toDate}];
}

#pragma mark - Private methods

- (id)MB_unarchive_withResults:(FMResultSet *)results {
    
    id resultObject;
    BOOL decoded = NO;
    
    // If the object can decode itself, then go ahead and
    // let it!
    if ( [[self class] conformsToProtocol:@protocol(NSCoding)] ) {
        resultObject = [NSKeyedUnarchiver unarchiveObjectWithData:[results objectForColumnName:@"objBody"]];
        decoded = YES;
    }
    else {
        resultObject = [[[self class] alloc] init];
    }
    
    // Load in any of the mamba properties
    objc_setAssociatedObject(resultObject, DHMambaObjectIDKey, [results objectForColumnName:@"objID"], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:[[results objectForColumnName:@"createTime"] doubleValue]];
    objc_setAssociatedObject(resultObject, DHMambaObjectCreateTimeKey, createDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSDate *updateDate = [NSDate dateWithTimeIntervalSince1970:[[results objectForColumnName:@"updateTime"] doubleValue]];
    objc_setAssociatedObject(resultObject, DHMambaObjectUpdateTimeKey, updateDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // if object can't decode itself, we need to do it
    if ( !decoded ) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:[results objectForColumnName:@"objBody"]];
        NSArray *properties = [self MB_class_propertyNames];
        for ( NSString *property in properties ) {
            [resultObject setValue:[unarchiver decodeObjectForKey:property] forKey:property];
        }
        [unarchiver finishDecoding];
    }
    return resultObject;
}

+ (void)MB_performAfterLoad:(id)loadedObject
{
    // Give object a chance to do anything special after load
    if ( [loadedObject respondsToSelector:@selector(mambaAfterLoad)]) {
        [loadedObject performSelector:@selector(mambaAfterLoad)];
    }
}

+ (void)MB_performAfterLoadOnArray:(NSArray *)loadedObjects
{
    for ( id loadedObject in loadedObjects ) {
        [self MB_performAfterLoad:loadedObject];
    }
}

//
// This method ripped uncerimoniously from a blog post here:
// http://iosdevelopertips.com/cocoa/nscoding-without-boilerplate.html?utm_source=iOSDevTips&utm_campaign=wordtwit&utm_medium=twitter
//
- (NSArray *)MB_class_propertyNames
{
    // Check for a cached value (we use _cmd as the cache key,
    // which represents @selector(propertyNames))
    NSMutableArray *array = objc_getAssociatedObject([self class], _cmd);
    if (array)
    {
        return array;
    }
    
    // Loop through our superclasses until we hit NSObject
    array = [NSMutableArray array];
    Class subclass = [self class];
    while (subclass != [NSObject class])
    {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(subclass,
                                                             &propertyCount);
        for (int i = 0; i < propertyCount; i++)
        {
            // Get property name
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            NSString *key = @(propertyName);
            
            // Check if there is a backing ivar
            char *ivar = property_copyAttributeValue(property, "V");
            if (ivar)
            {
                // Check if ivar has KVC-compliant name
                NSString *ivarName = @(ivar);
                if ([ivarName isEqualToString:key] ||
                    [ivarName isEqualToString:[@"_" stringByAppendingString:key]])
                {
                    // setValue:forKey: will work
                    [array addObject:key];
                }
                free(ivar);
            }
        }
        free(properties);
        subclass = [subclass superclass];
    }
    
    // Cache and return array
    objc_setAssociatedObject([self class], _cmd, array, 
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return array;
}

+ (NSArray *)MB_search:(NSArray *)criteria parameters:(NSDictionary *)parameters limit:(NSUInteger)limit orderBy:(DHMambaObjectOrderBy)orderBy {
    
    NSString *collection = NSStringFromClass([self class]);
    
    // setup the where clause
    NSString *where = @"";
    for ( NSString *whereCriteria in criteria ) {
        if ( ![where isEqualToString:@""] ) {
            where = [where stringByAppendingString:@" and "];
        }
        where = [where stringByAppendingString:whereCriteria];
    }
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [DHMambaStore selectFromCollection:collection where:where parameters:parameters order:orderBy limit:limit resultBlock:^(FMResultSet *results) {

        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (NSNumber *)MB_count:(NSString *)criteria parameters:(NSDictionary *)parameters {
    
    NSString *collection = NSStringFromClass([self class]);
    return [DHMambaStore countFromCollection:collection where:criteria parameters:parameters];
}

@end
