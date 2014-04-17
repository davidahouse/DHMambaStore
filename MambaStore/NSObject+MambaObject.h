//
//  NSObject+MambaObject.h
//  
//
//  Created by David House on 1/23/14.
//
//

#import <Foundation/Foundation.h>

//
// OrderBy enumeration
//
typedef NS_ENUM(NSUInteger, MambaObjectOrderBy) {
    MambaObjectOrderByKey = 0,
    MambaObjectOrderByTitle = 1,
    MambaObjectOrderByForeignKey = 2,
    MambaObjectOrderByCreateTime = 3,
    MambaObjectOrderByUpdateTime = 4,
    MambaObjectOrderByOrderNumber = 5,
    MambaObjectOrderByKeyDescending = 6,
    MambaObjectOrderByTitleDescending = 7,
    MambaObjectOrderByForeignKeyDescending = 8,
    MambaObjectOrderByCreateTimeDescending = 9,
    MambaObjectOrderByUpdateTimeDescending = 10,
    MambaObjectOrderByOrderNumberDescending = 11
};

//
// Protocol for extending the object with specific properties that MambaStore
// will use when saving/loading the object.
//
@protocol MambaObjectProperties <NSObject>
@optional
- (NSString *)mambaObjectKey;
- (NSString *)mambaObjectForeignKey;
- (void)setMambaObjectForeignKey:(NSString *)foreignKey;
- (NSString *)mambaObjectTitle;
- (NSNumber *)mambaObjectOrderNumber;
- (NSArray *)mambaObjectIgnoreProperties;
@end

//
// Protocol for extending the object with methods that allow you to customize
// saving and loading of the object
//
@protocol MambaObjectMethods <NSObject>
@optional
- (void)mambaAfterSave;
- (void)mambaAfterLoad;
- (void)mambaAfterDelete;
@end

//
// MambaObject category
//
@interface NSObject (MambaObject)

#pragma mark - Convenience methods for getting & setting mamba specific properties
- (BOOL)MB_has_objID;
- (NSString *)MB_objID;
- (NSString *)MB_objKey;
- (NSString *)MB_objForeignKey;
- (NSString *)MB_objTitle;
- (NSNumber *)MB_objOrderNumber;
- (NSData *)MB_objData;
- (NSDate *)MB_createTime;
- (NSDate *)MB_updateTime;

#pragma mark - CRUD methods
- (void)MB_save;
- (void)MB_delete;
- (void)MB_deleteAll;

#pragma mark - Search methods
+ (id)MB_loadWithID:(NSString *)objectID;
+ (id)MB_findWithKey:(NSString *)key;

//
// Find with no conditions
//
+ (NSArray *)MB_findAll;
+ (NSArray *)MB_findAllLimit:(NSUInteger)limit;
+ (NSArray *)MB_findAllOrderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findAllLimit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objKey field
//
+ (NSArray *)MB_findInKey:(NSString *)key;
+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit;
+ (NSArray *)MB_findInKey:(NSString *)key orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find matching a title
//
+ (NSArray *)MB_findWithTitle:(NSString *)title;
+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit;
+ (NSArray *)MB_findWithTitle:(NSString *)title orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objTitle field
//
+ (NSArray *)MB_findInTitle:(NSString *)title;
+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit;
+ (NSArray *)MB_findInTitle:(NSString *)title orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find matching a foreign key
//
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey;
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit;
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objForeignKey field
//
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey;
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit;
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// OrderBy searching
//
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to;
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit;
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to orderBy:(MambaObjectOrderBy)orderBy;
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Date searching
//
+ (NSArray *)MB_createdMostRecent:(NSUInteger)top;
+ (NSArray *)MB_createdLeastRecent:(NSUInteger)top;
+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to;
+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit;
+ (NSArray *)MB_updatedMostRecent:(NSUInteger)top;
+ (NSArray *)MB_updatedLeastRecent:(NSUInteger)top;
+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to;
+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit;

#pragma mark - Count Methods
+ (NSNumber *)MB_countAll;
+ (NSNumber *)MB_countWithKey:(NSString *)key;
+ (NSNumber *)MB_countLikeKey:(NSString *)key;
+ (NSNumber *)MB_countWithTitle:(NSString *)title;
+ (NSNumber *)MB_countLikeTitle:(NSString *)title;
+ (NSNumber *)MB_countWithForeignKey:(NSString *)foreignKey;
+ (NSNumber *)MB_countLikeForeignKey:(NSString *)foreignKey;
+ (NSNumber *)MB_countOrderedFrom:(NSNumber *)fromOrderNumber to:(NSNumber *)toOrderNumber;
+ (NSNumber *)MB_countCreatedFrom:(NSDate *)fromDate to:(NSDate *)toDate;
+ (NSNumber *)MB_countUpdatedFrom:(NSDate *)fromDate to:(NSDate *)toDate;

@end
