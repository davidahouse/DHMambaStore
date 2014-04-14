//
//  NSObject+MambaObject.h
//  
//
//  Created by David House on 1/23/14.
//
//

#import <Foundation/Foundation.h>

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
+ (NSArray *)MB_findAll;
+ (id)MB_find:(NSString *)key;
+ (NSArray *)MB_findInTitle:(NSString *)condition;
+ (NSArray *)MB_findWithTitle:(NSString *)title;
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey;
+ (NSArray *)MB_createdMostRecent:(int)top;
+ (NSArray *)MB_createdLeastRecent:(int)top;
+ (NSArray *)MB_updatedMostRecent:(int)top;
+ (NSArray *)MB_updatedLeastRecent:(int)top;

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
