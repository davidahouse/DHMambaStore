//
//  NSObject+MambaObject.m
//  
//
//  Created by David House on 1/23/14.
//
//

#import "NSObject+MambaObject.h"
#import "MambaStore.h"
#import <Objc/runtime.h>


static char const * const MambaObjectIDKey = "MambaObjectID";
static char const * const MambaObjectCreateTimeKey = "MambaObjectCreateTime";
static char const * const MambaObjectUpdateTimeKey = "MambaObjectUpdateTime";

@implementation NSObject (MambaObject)


#pragma mark - Convenience methods for getting & setting mamba specific properties
- (BOOL)MB_has_objID {

    if ( objc_getAssociatedObject(self, MambaObjectIDKey) ) {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSString *)MB_objID {
    
    // Look in associated object storage for the object ID. If not found, we need to create one!
    if ( [self MB_has_objID] ) {
        NSString *objID = objc_getAssociatedObject(self, MambaObjectIDKey);
        return objID;
    }
    else {
        NSString *objID = [[NSUUID UUID] UUIDString];
        objc_setAssociatedObject(self, MambaObjectIDKey, objID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if ( objc_getAssociatedObject(self, MambaObjectCreateTimeKey) ) {

        NSDate *createTime = objc_getAssociatedObject(self, MambaObjectCreateTimeKey);
        return createTime;
    }
    else {
        return nil;
    }
}

- (NSDate *)MB_updateTime {
    
    // Look in associated object storage. If not found, we need to create one!
    if ( objc_getAssociatedObject(self, MambaObjectCreateTimeKey) ) {
        
        NSDate *updateTime = objc_getAssociatedObject(self, MambaObjectUpdateTimeKey);
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
        [MambaStore insertObject:self];
    }
    else {
        [MambaStore updateObject:self];
    }
    
    if ( [self respondsToSelector:@selector(mambaAfterSave)] ) {
        [self performSelector:@selector(mambaAfterSave)];
    }
}

- (void)MB_delete {
    
    [MambaStore deleteObject:self];

    if ( [self respondsToSelector:@selector(mambaAfterDelete)] ) {
        [self performSelector:@selector(mambaAfterDelete)];
    }
}

- (void)MB_deleteAll {
    
    NSString *collection = NSStringFromClass([self class]);
    [MambaStore emptyCollection:collection];
}

#pragma mark - Search methods
+ (id)MB_loadWithID:(NSString *)objectID
{
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block id resultObject = nil;
    [MambaStore selectFromCollection:collection where:[NSString stringWithFormat:@"objID = '%@'",objectID] order:@"" limit:-1 resultBlock:^(FMResultSet *results) {
        
        resultObject = [self MB_unarchive_withResults:results];
    }];
    [self MB_performAfterLoad:resultObject];
    return resultObject;
}

+ (NSArray *)MB_findAll {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [MambaStore selectFromCollection:collection where:@"" order:@"orderNumber" limit:-1 resultBlock:^(FMResultSet *results) {
        
        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (id)MB_find:(NSString *)key {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block id resultObject = nil;
    [MambaStore selectFromCollection:collection where:[NSString stringWithFormat:@"objKey = '%@'",key] order:@"" limit:-1 resultBlock:^(FMResultSet *results) {
        
        resultObject = [self MB_unarchive_withResults:results];
    }];
    [self MB_performAfterLoad:resultObject];
    return resultObject;
}

+ (NSArray *)MB_findInTitle:(NSString *)condition {
    return [self MB_search:@[[NSString stringWithFormat:@"objTitle like '%%%@%%'",condition]]];
}

+ (NSArray *)MB_findWithTitle:(NSString *)title {
    return [self MB_search:@[[NSString stringWithFormat:@"objTitle = '%@'",title]]];
}

+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey {

    return [self MB_search:@[[NSString stringWithFormat:@"objForeignKey = '%@'",foreignKey]]];
}

+ (NSArray *)MB_createdMostRecent:(int)top {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [MambaStore selectFromCollection:collection where:@"" order:@"createTime DESC" limit:top resultBlock:^(FMResultSet *results) {
        
        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (NSArray *)MB_createdLeastRecent:(int)top {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [MambaStore selectFromCollection:collection where:@"" order:@"createTime" limit:top resultBlock:^(FMResultSet *results) {

        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (NSArray *)MB_updatedMostRecent:(int)top {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [MambaStore selectFromCollection:collection where:@"" order:@"updateTime DESC" limit:top resultBlock:^(FMResultSet *results) {
        
        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (NSArray *)MB_updatedLeastRecent:(int)top {
    
    // get the default collection name
    NSString *collection = NSStringFromClass([self class]);
    
    __block NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    [MambaStore selectFromCollection:collection where:@"" order:@"updateTime" limit:top resultBlock:^(FMResultSet *results) {
        
        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

#pragma mark - Count Methods

/**
 *  <#Description#>
 *
 *  @return <#return value description#>
 */
+ (NSNumber *)MB_countAll
{
    return [self MB_count:@[@""]];
}

+ (NSNumber *)MB_countWithKey:(NSString *)key
{
    return [self MB_count:@[[NSString stringWithFormat:@"objKey = '%@'",key]]];
}

+ (NSNumber *)MB_countLikeKey:(NSString *)key
{
    return [self MB_count:@[[NSString stringWithFormat:@"objKey like '%%%@%%'",key]]];
}

+ (NSNumber *)MB_countWithTitle:(NSString *)title
{
    return [self MB_count:@[[NSString stringWithFormat:@"objTitle = '%@'",title]]];
}

+ (NSNumber *)MB_countLikeTitle:(NSString *)title
{
    return [self MB_count:@[[NSString stringWithFormat:@"objTitle like '%%%@%%'",title]]];
}

+ (NSNumber *)MB_countWithForeignKey:(NSString *)foreignKey
{
    return [self MB_count:@[[NSString stringWithFormat:@"objForeignKey = '%@'",foreignKey]]];
}

+ (NSNumber *)MB_countLikeForeignKey:(NSString *)foreignKey
{
    return [self MB_count:@[[NSString stringWithFormat:@"objForeignKey like '%%%@%%'",foreignKey]]];
}

+ (NSNumber *)MB_countOrderedFrom:(NSNumber *)fromOrderNumber to:(NSNumber *)toOrderNumber
{
    return [self MB_count:@[[NSString stringWithFormat:@"orderNumber >= %@",fromOrderNumber],[NSString stringWithFormat:@"orderNumber <= %@",toOrderNumber]]];
}

+ (NSNumber *)MB_countCreatedFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    return @0;
}

+ (NSNumber *)MB_countUpdatedFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    return @0;
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
    objc_setAssociatedObject(resultObject, MambaObjectIDKey, [results objectForColumnName:@"objID"], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:[[results objectForColumnName:@"createTime"] doubleValue]];
    objc_setAssociatedObject(resultObject, MambaObjectCreateTimeKey, createDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSDate *updateDate = [NSDate dateWithTimeIntervalSince1970:[[results objectForColumnName:@"updateTime"] doubleValue]];
    objc_setAssociatedObject(resultObject, MambaObjectUpdateTimeKey, updateDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
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

+ (NSArray *)MB_search:(NSArray *)criteria {
    
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
    [MambaStore selectFromCollection:collection where:where order:@"orderNumber, objTitle" limit:-1 resultBlock:^(FMResultSet *results) {

        id resultObject = [self MB_unarchive_withResults:results];
        [resultArray addObject:resultObject];
    }];
    [self MB_performAfterLoadOnArray:resultArray];
    return resultArray;
}

+ (NSNumber *)MB_count:(NSArray *)criteria {
    
    NSString *collection = NSStringFromClass([self class]);
    
    // setup the where clause
    NSString *where = @"";
    for ( NSString *whereCriteria in criteria ) {
        if ( ![where isEqualToString:@""] ) {
            where = [where stringByAppendingString:@" and "];
        }
        where = [where stringByAppendingString:whereCriteria];
    }
    
    return [MambaStore countFromCollection:collection where:where];
}

@end
