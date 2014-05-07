//
//  ChildObject.h
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import <Foundation/Foundation.h>
#import "NSObject+DHMambaObject.h"

@interface ChildObject : NSObject<DHMambaObjectProperties>

#pragma mark - Properties
@property (nonatomic,strong) NSString *childName;
@property (nonatomic,strong) NSString *parentID;

@end
