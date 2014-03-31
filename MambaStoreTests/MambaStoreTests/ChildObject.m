//
//  ChildObject.m
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import "ChildObject.h"

@implementation ChildObject

#pragma mark - Mamba Object Properties
- (NSString *)mambaObjectForeignKey {
    return self.parentID;
}

- (void)setMambaObjectForeignKey:(NSString *)foreignKey {
    self.parentID = foreignKey;
}

@end
