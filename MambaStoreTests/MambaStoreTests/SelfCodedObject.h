//
//  SelfCodedObject.h
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import <Foundation/Foundation.h>
#import "NSObject+MambaObject.h"

@interface SelfCodedObject : NSObject<NSCoding>

#pragma mark - Properties
@property (nonatomic,strong) NSString *title;
@property (nonatomic,assign) CGRect frame;

@end
