//
//  ChildObject.h
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import <Foundation/Foundation.h>
#import "NSObject+MambaObject.h"

@interface ChildObject : NSObject<MambaObjectProperties>

#pragma mark - Properties
@property (nonatomic,strong) NSString *childName;
@property (nonatomic,strong) NSString *parentID;

@end
