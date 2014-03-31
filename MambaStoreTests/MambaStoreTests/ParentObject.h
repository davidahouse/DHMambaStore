//
//  ParentObject.h
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import <Foundation/Foundation.h>
#import "NSObject+MambaObject.h"

@interface ParentObject : NSObject<MambaObjectProperties,MambaObjectMethods>

#pragma mark - Properties
@property (nonatomic,strong) NSString *parentName;
@property (nonatomic,strong) NSMutableArray *children;

@end
