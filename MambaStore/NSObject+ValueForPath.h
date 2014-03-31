//
//  NSObject+ValueForPath.h
//  
//
//  Created by David House on 9/27/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (ValueForPath)

- (id)valueForPath:(NSArray *)path;
- (void)setValue:(id)value forPath:(NSArray *)path;

@end
