//
//  SelfCodedObject.m
//  MambaStoreTests
//
//  Created by David House on 3/30/14.
//
//

#import "SelfCodedObject.h"

@implementation SelfCodedObject

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super init] ) {
        _title = [aDecoder decodeObjectForKey:@"title"];
        _frame = CGRectMake([aDecoder decodeIntegerForKey:@"frameX"], [aDecoder decodeIntegerForKey:@"frameY"], [aDecoder decodeIntegerForKey:@"frameWidth"], [aDecoder decodeIntegerForKey:@"frameHeight"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeInteger:self.frame.origin.x forKey:@"frameX"];
    [aCoder encodeInteger:self.frame.origin.y forKey:@"frameY"];
    [aCoder encodeInteger:self.frame.size.width forKey:@"frameWidth"];
    [aCoder encodeInteger:self.frame.size.height forKey:@"frameHeight"];
}

@end
