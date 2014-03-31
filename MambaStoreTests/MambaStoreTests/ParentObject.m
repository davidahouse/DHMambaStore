//
//  ParentObject.m
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import "ParentObject.h"
#import "ChildObject.h"

@implementation ParentObject

#pragma mark - Properties
- (NSMutableArray *)children
{
    if ( !_children ) {
        _children = [[NSMutableArray alloc] init];
    }
    return _children;
}

#pragma mark - MambaObjectProperties
- (NSString *)mambaObjectTitle
{
    return self.parentName;
}

- (NSArray *)mambaObjectIgnoreProperties {
    return @[@"children"];
}

#pragma mark - MambaObjectMethods
- (void)mambaAfterLoad
{
    NSArray *childObjects = [ChildObject MB_findWithForeignKey:[self MB_objKey]];
    for ( ChildObject *child in childObjects ) {
        [self.children addObject:child];
    }
}

- (void)mambaAfterSave
{
    for ( ChildObject *child in self.children ) {
        [child setMambaObjectForeignKey:[self MB_objKey]];
        [child MB_save];
    }
}

- (void)mambaAfterDelete
{
    for ( ChildObject *child in self.children ) {
        [child MB_delete];
    }
}


@end
