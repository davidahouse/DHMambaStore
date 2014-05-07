## About

DHMambaStore is an ObjectiveC library that makes it easy to persist a set of objects. This
library is geared towards developers who want more power than NSCoding can provide, yet
not as much power as CoreData. The library is designed to work with the least amount of code
for simple tasks, while providing enough hooks for more advanced needs.

This is still a very new library and has not been extensively tested or used in projects. Use
at your own risk until more validation is done.

## Installing

To install, grab the source and add to your project, or just use CocoaPods. If using CocoaPods,
just add this to your podfile:

```ruby
  pod 'DHMambaStore', :git => 'https://github.com/davidahouse/DHMambaStore.git'
```

## Requirements

- Xcode 5, ARC.
- iOS 6.1+
- FMDB (this is handled automatically if you use CocoaPods)

## Getting started

### Persist an object

Import the main MambaStore header

```objectivec
  #import "NSObject+DHMambaStore.h"
```

Take any instance of an object and store it.

```objectivec
  MyObject *anObject = [MyObject alloc] init];
  [anObject MB_save];
```

Done!

### Load an object by ID

When an object is persisted, an ID is automatically created and attached
to the object. This ID is a string and you can get it using the MB_objID method:

```objectivec
  MyObject *anObject = [MyObject alloc] init];
  [anObject MB_save];
  NSString *objID = [anObject MB_objID];
```

When you have the ID, you can reload that object from the store using it.

```objectivec
  MyObject *loadedObject = [MyObject MB_loadWithID:objID];
```

### Load all the objects!

```objectivec
  NSArray *allTheObjects = [MyObject MB_findAll];
```

### Delete an object from the store

```objectivec
  MyObject *anObject = [MyObject MB_loadWithID:objID];
  [anObject MB_delete];
```

### Delete all the objects for a class type

```objectivec
  [MyObject MB_deleteAll];
```

### Getting timestamps on store objects

```objectivec
  MyObject *anObject = [MyObject MB_loadWithID:objID];
  NSDate *created = [anObject MB_createTime];
  NSDate *updated = [anObject MB_updateTime];
```

### Finding objects based on the timestamps

```objectivec
  NSArray *firstCreated = [MyObject MB_createdLeastRecent:1];
  NSArray *last10Created = [MyObject MB_createdMostRecent:10];
  NSArray *last5Updated = [MyObject MB_updatedMostRecent:5];
  NSArray *first20Updated = [MyObject MB_updatedLeastRecent:20];
```

### Creating your own key

Your objects may have their own key that you want to use to find by.
To tell the MambaStore that you want to use your own key you need to
implement a method on the DHMambaObjectProperties protocol.

```objectivec

  @interface MyObject : NSObject<DHMambaObjectProperties>

  @property (nonatomic,strong) NSString *uniqueKey;

  @end

  @implementation MyObject

  - (NSString *)mambaObjectKey
  {
    return self.uniqueKey;
  }

  @end

```

Now when this object is stored, the uniqueKey property value is used to store the
'key' field. This opens up a new method for loading the object.

```objectivec
    MyObject *byKey = [MyObject MB_findWithKey:@"akey"];
```

### Everyone needs a title

A common pattern is for the UI to show a list of your objects and they all have a title. Also
common is the need to search/filter objects by this title. The MambaObjectProperties protocol
includes another helper method to let Mamba know which property of your object it can use
as the title to provide additional helpers.

```objectivec

  - (NSString *)mambaObjectTitle
  {
    return self.name;
  }
```

And the helper methods for title are MB_findWithTitle which tries to match the title exactly,
and MB_findInTitle that provides for partial matching.

```objectivec

  NSArray *resultsWithExactTitle = [MyObject MB_findWithTitle:@"A specific title"];
  NSArray *resultsWithPartialTitle = [MyObject MB_findInTitle:@"partial"];

```

### Foreign key

Another common need is to connect records together in a parent/child relationship. Mamba provides two methods
in the DHMambaObjectProperties protocol to get and set the foreign key for an object. Once you have implemented
this, the helper method MB_findWithForeignKey is available for loading records.

```objectivec
  - (NSString *)mambaObjectForeignKey
  {
    return self.parentID;
  }

  - (void)setMambaObjectForeignKey:(NSString *)foreignKey
  {
    self.parentID = foreignKey;
  }
```

```
  NSArray *children = [MyChildObject MB_findWithForeignKey:@"123"];
```

### Ordering

If you need to order your find results, you can implement the mambaObjectOrderNumber method and provide
a number to use. This order number is used in all the MB_find* methods.

```objectivec
  - (NSNumber *)mambaObjectOrderNumber
  {
    return self.customOrderNumber;
  }
```

### Leaving out properties from the encoding

By default, Mamba Store will attempt to persist your object by inspecting all the properties of the object and
encoding/decoding them. There are cases where you don't want this behavior for certain properties, so you can
let the store know which properties should not be encoded/decoded automatically by implementing the
mambaObjectIgnoreProperties method in the MambaObjectProperties protocol.

```objectivec
  - (NSArray *)mambaObjectIgnoreProperties
  {
    return @"childrenArray";
  }
```

### Do your own encoding

If your object implements the NSCoding protocol, Mamba Store will use your implementation instead of trying
to do its own automatic version. This gives you complete control over what is encoded and decoded in your
object.

### Adding behaviors after store operations

You can also customize what happens after your object is saved, loaded or deleted from the store by implementing
the MambaObjectMethods protocol and responding to one of the optional methods.

```objectivec
  - (void)mambaAfterSave
  {
    // do any additional work here like telling your child objects to save themselves.
  }

  - (void)mambaAfterLoad
  {
    // also useful for loading in your child objects
  }

  - (void)mambaAfterDelete
  {
    // again, good for cascading deletes down to your children
  }
```

### Examples

The MambaStoreTests project contains some automated tests that are a good place to see examples of how
to use the store. An example of how to handle Parent/Child objects is there, along with an example of
doing your own encoding.

A more complete example can be found in my MambaTweets repo: [MambaTweets](https://github.com/davidahouse/MambaTweets)

### License

MambaStore is under the MIT license, please see the included LICENSE file.

### Contact

- [David House](http://github.com/davidahouse) ([@davidahouse](https://twitter.com/davidahouse))
