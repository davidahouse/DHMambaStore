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

/**
 * Protocol for extending the object with specific properties that MambaStore
 * will use when saving/loading the object.
 */
@protocol MambaObjectProperties <NSObject>
@optional

/** Return the key to use when saving this object into the store.
 * Can be later retrieved using this key.
 * @return The key
 */
- (NSString *)mambaObjectKey;

/** Return the foreign key to use when saving this object into the
 * store.
 * @return The foreign key
 */
- (NSString *)mambaObjectForeignKey;

/** Setter for the foreign key. Used by other objects when there
 * is a parent/child relationship they want to setup.
 * @param foreignKey The foreign key to set
 */
- (void)setMambaObjectForeignKey:(NSString *)foreignKey;

/** Return the value to be stored in the title field in the store.
 * @return the title
 */
- (NSString *)mambaObjectTitle;

/** Return the order number to be stored in the store for this object.
 * @return The order number
 */
- (NSNumber *)mambaObjectOrderNumber;

/** Return an array of properties to ignore when the automatic
 * serialization happens on your object.
 * @return An array of property names (NSString)
 */
- (NSArray *)mambaObjectIgnoreProperties;

@end

/** Protocol for extending the object with methods that allow you to customize
 * saving and loading of the object
 */
@protocol MambaObjectMethods <NSObject>
@optional

/** Called after the object is saved into the repository */
- (void)mambaAfterSave;

/** Called after the object is loaded from the repository */
- (void)mambaAfterLoad;

/** Called after the object is deleted from the respository */
- (void)mambaAfterDelete;

@end


/** MambaObject category
 * Can be applied to any object. The properties of that object will
 * be automatically serialized and deserialized from the store.
 */
 @interface NSObject (MambaObject)

#pragma mark - Convenience methods for getting & setting mamba specific properties

/** Each object in the store receives an objID. This method can be
 * used to test if the value has been set yet.
 * @return YES if the object has an objID set, or NO if not
 */
- (BOOL)MB_has_objID;

/** Returns the objID for the object if one has been set. These
 * IDs are automatically applied to the object once it has been
 * saved into the store.
 * @return The object id, or nil if none has been set.
 */
- (NSString *)MB_objID;

/** Returns the objKey for the object. In order for an object
 * to return a value for this, it must implement the mambaObjectKey
 * method in the MambaObjectProperties protocol. Note that objID 
 * and objKey are different in that objID is automatically applied
 * by the store code, while objKey is a user defined value.
 * @return the key associated with this object
 */
- (NSString *)MB_objKey;

/** Returns the objForeignKey for the object. In order for an object
 * to return a value for this, it must implement the mambaObjectForeignKey
 * method in the MambaObjectProperties protocol.
 * @return The foreign key
 */
- (NSString *)MB_objForeignKey;

/** Returns the objTitle for the object. In order for an object to return a 
 * value for this, it must implement the mambaObjectTitle method in the
 * MambaObjectProperties protocol.
 * @return The title
 */
- (NSString *)MB_objTitle;

/** Returns the objOrderNumber for the object.
 * @return The order number for the object
 */
- (NSNumber *)MB_objOrderNumber;

/** Returns the archived data for the object in the store. The data is created
 * using the KeyedArchiver either automatically, or manually if you implement the
 * NSCoding protocol.
 * @return the archived data
 */
- (NSData *)MB_objData;

/** Returns the time the object was created in the store.
 * @return the create time
 */
- (NSDate *)MB_createTime;

/** Returns the time the object was last updated in the store.
 * @return the update time
 */
- (NSDate *)MB_updateTime;

#pragma mark - CRUD methods
/** Saves the object into the store. If it hasn't been saved to the store already
 * it will be inserted. If it already exists in the store it will be updated.
 */
- (void)MB_save;

/** Deletes the object from the store.
 */
- (void)MB_delete;

/** Deletes all objects of the receivers class in the store
 */
- (void)MB_deleteAll;

#pragma mark - Search methods

/** Loads an object from the store using its object ID.
 * @param objectID The objectID of the object to load
 * @return The loaded object, or nil if it is not found.
 */
+ (id)MB_loadWithID:(NSString *)objectID;

/** Loads an object from the store using its key.
 * @param key The key to use to find the object in the store.
 * @return The loaded object, or nil if it is not found.
 */
+ (id)MB_findWithKey:(NSString *)key;

//
// Find with no conditions
//

/** Find all objects of the class.
 * @return An array of found objects
 */
+ (NSArray *)MB_findAll;

/** Find all objects of the class, limited to a certain number of results.
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findAllLimit:(NSUInteger)limit;

/** Find all objects of the class, with a specified order.
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findAllOrderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects of the class, limited to a certain number of results and with a specified order.
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findAllLimit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objKey field
//

/** Find all objects with a value contained in the key.
 * @param key The value to search in the key field
 * @return An array of found objects
 */
+ (NSArray *)MB_findInKey:(NSString *)key;

/** Find all objects with a value contained in the key, limited to a certain number of results.
 * @param key The value to search in the key field
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit;

/** Find all objects with a value contained in the key, with a specified order.
 * @param key The value to search in the key field
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInKey:(NSString *)key orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects with a value contained in the key, limited to a certain number of results with a specified order.
 * @param key The value to search in the key field
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInKey:(NSString *)key limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find matching a title
//

/** Find all objects matching a specific title
 * @param title The exact title to match
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithTitle:(NSString *)title;

/** Find all objects matching a specific title, limited to a certain number of results
 * @param title The exact title to match
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit;

/** Find all objects matching a specific title, ordered by a specific order
 * @param title The exact title to match
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithTitle:(NSString *)title orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects matching a specific title, limited to a certain number of results and ordered by a specified order
 * @param title The exact title to match
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objTitle field
//

/** Find all objects with a value found in the title
 * @param title The value to search in the title
 * @return An array of found objects
 */
+ (NSArray *)MB_findInTitle:(NSString *)title;

/** Find all objects with a value found in the title limited by a certain number of results.
 * @param title The value to search in the title
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit;

/** Find all objects with a value found in the title ordered by a specified order.
 * @param title The value to search in the title
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInTitle:(NSString *)title orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects with a value found in the title, limited by a certain number of results and ordered by a specified order.
 * @param title The value to search in the title
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInTitle:(NSString *)title limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find matching a foreign key
//

/** Find all objects matching a specific foreign key
 * @param foreignKey The exact foreign key to match
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey;

/** Find all objects matching a specific foreign key, limited to a certain number of results.
 * @param foreignKey The exact foreign key to match
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit;

/** Find all objects matching a specific foreign key, ordered by a specified order.
 * @param foreignKey The exact foreign key to match
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects matching a specific foreign key, limited to a certain number of results and ordered by a specified order
 * @param foreignKey The exact foreign key to match
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Find doing a LIKE on the objForeignKey field
//

/** Find all objects with a value found in the foreign key.
 * @param foreignKey The value to search in the foreign key
 * @return An array of found objects
 */
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey;

/** Find all objects with a value found in the foreign key, limited by a certain number of results
 * @param foreignKey The value to search in the foreign key
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit;

/** Find all objects with a value found in the foreign key, ordered by a specified order.
 * @param foreignKey The value to search in the foreign key
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects with a value found in the foreign key, limited by a certain number of results and ordered by a specified order.
 * @param foreignKey The value to search in the foreign key
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findInForeignKey:(NSString *)foreignKey limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// OrderBy searching
//

/** Find all objects with an orderNumber with a certain range
 * @param from The lower end of the range to search for
 * @param to The high end of the range to search for
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to;

/** Find all objects with an orderNumber with a certain range limited to a certain number of results.
 * @param from The lower end of the range to search for
 * @param to The high end of the range to search for
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit;

/** Find all objects with an orderNumber with a certain range ordered by a specified order.
 * @param from The lower end of the range to search for
 * @param to The high end of the range to search for
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to orderBy:(MambaObjectOrderBy)orderBy;

/** Find all objects with an orderNumber with a certain range, limited to a certain number of results and ordered
 * by a specified order.
 * @param from The lower end of the range to search for
 * @param to The high end of the range to search for
 * @param limit The maximum number of objects to return
 * @param orderBy The condition to order the results by
 * @return An array of found objects
 */
+ (NSArray *)MB_findWithOrderNumberFrom:(NSNumber *)from to:(NSNumber *)to limit:(NSUInteger)limit orderBy:(MambaObjectOrderBy)orderBy;

//
// Date searching
//

/** Find the most recently created objects.
 * @param top The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_createdMostRecent:(NSUInteger)top;

/** Find the least recently created objects.
 * @param top The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_createdLeastRecent:(NSUInteger)top;

/** Find the objects created in a certain date range
 * @param from The lower end of the date range
 * @param to The higher end of the date range
 * @return An array of found objects
 */
+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to;

/** Find the objects created in a certain date range
 * @param from The lower end of the date range
 * @param to The higher end of the date range
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_createdFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit;

/** Find the most recently updated objects.
 * @param top The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_updatedMostRecent:(NSUInteger)top;

/** Find the least recently updated objects.
 * @param top The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_updatedLeastRecent:(NSUInteger)top;

/** Find the objects updated in a certain date range
 * @param from The lower end of the date range
 * @param to The higher end of the date range
 * @return An array of found objects
 */
+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to;

/** Find the objects updated in a certain date range
 * @param from The lower end of the date range
 * @param to The higher end of the date range
 * @param limit The maximum number of objects to return
 * @return An array of found objects
 */
+ (NSArray *)MB_updatedFrom:(NSDate *)from to:(NSDate *)to limit:(NSUInteger)limit;

#pragma mark - Count Methods

/** Count the number of objects in the store
 * @return The number of objects found
 */
+ (NSNumber *)MB_countAll;

/** Count the number of objects with a specific key
 * @param key The specific key to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countWithKey:(NSString *)key;

/** Count the number of objects like a key value
 * @param key The key value to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countLikeKey:(NSString *)key;

/** Count the number of objects with a specific title
 * @param title The specific title to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countWithTitle:(NSString *)title;

/** Count the number of objects like a title value
 * @param title The title value to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countLikeTitle:(NSString *)title;

/** Count the number of objects with a specific foreignKey
 * @param foreignKey The specific foreignKey to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countWithForeignKey:(NSString *)foreignKey;

/** Count the number of objects like a foreignKey value
 * @param foreignKey The foreignKey value to use when counting
 * @return The number of objects found
 */
+ (NSNumber *)MB_countLikeForeignKey:(NSString *)foreignKey;

/** Count the number of objects with an orderNumber in a range
 * @param fromOrderNumber The lower end of the range
 * @param toOrderNumber The high end of the range
 * @return The number of objects found
 */
+ (NSNumber *)MB_countOrderedFrom:(NSNumber *)fromOrderNumber to:(NSNumber *)toOrderNumber;

/** Count the number of objects created in a range.
 * @param fromDate The lower end of the date range
 * @param toDate The higher end of the date range
 * @return The number of objects found
 */
+ (NSNumber *)MB_countCreatedFrom:(NSDate *)fromDate to:(NSDate *)toDate;

/** Count the number of objects updated in a range.
 * @param fromDate The lower end of the date range
 * @param toDate The higher end of the date range
 * @return The number of objects found
 */
+ (NSNumber *)MB_countUpdatedFrom:(NSDate *)fromDate to:(NSDate *)toDate;

@end
