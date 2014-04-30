//
//  NSObject+ValueForPath.m
//  
//
//  Created by David House on 9/27/13.
//  Copyright (c) 2014 David House <davidahouse@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "NSObject+ValueForPath.h"

@implementation NSObject (ValueForPath)

- (id)valueForPath:(NSArray *)path {
    
    if ( [path count] == 0 ) {
        return nil;
    }
    else if ( [path count] == 1 ) {
        
        if ( [self valueForKey:[path objectAtIndex:0]] &&
            [self valueForKey:[path objectAtIndex:0]] != [NSNull null]) {
            return [self valueForKey:[path objectAtIndex:0]];
        }
        else {
            return nil;
        }
    }
    else {
        // first take first element out of the array
        id first = [path objectAtIndex:0];
        NSArray *restOfPath = [NSArray arrayWithArray:[path objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [path count] - 1)]]];
        
        // if we are an array, then the path should be an index or special string. Otherwise just pass along our valueForKey
        if ( [self respondsToSelector:@selector(objectAtIndex:)] ) {
            
            NSArray *selfArray = (NSArray *)self;
            
            if ( [first isEqualToString:@"first"] ) {
                
                return [[selfArray objectAtIndex:0] valueForPath:restOfPath];
            }
            else if ( [first isEqualToString:@"last"] ) {
                return [[selfArray objectAtIndex:[selfArray count] - 1] valueForPath:restOfPath];
            }
            else {
                return [[selfArray objectAtIndex:[first intValue]] valueForPath:restOfPath];
            }
        }
        else {
            return [[self valueForKey:first] valueForPath:restOfPath];
        }
    }
}

- (void)setValue:(id)value forPath:(NSArray *)path {
 
    if ( [path count] == 0 ) {
        // probably shouldn't ever get here, something bad happened
    }
    else if ( [path count] == 1 ) {
 
        [self setValue:value forKey:[path objectAtIndex:0]];
    }
    else {
 
        // first take first element out of the array
        id first = [path objectAtIndex:0];
        NSArray *restOfPath = [NSArray arrayWithArray:[path objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [path count] - 1)]]];
 
        // if we are an array, then the path should be an index or special string. Otherwise just pass along our valueForKey
        if ( [self respondsToSelector:@selector(objectAtIndex:)] ) {
 
            NSArray *selfArray = (NSArray *)self;
 
            if ( [first isEqualToString:@"first"] ) {
 
                return [[selfArray objectAtIndex:0] setValue:value forPath:restOfPath];
            }
            else if ( [first isEqualToString:@"last"] ) {
                return [[selfArray objectAtIndex:[selfArray count] - 1] setValue:value forPath:restOfPath];
            }
            else {
 
                return [[selfArray objectAtIndex:[first intValue]] setValue:value forPath:restOfPath];
            }
        }
        else {
 
            // If we are at the end of the path with only a single dictionary
            // below, we should make sure it is mutable before going into it.
            // Also if it doesn't exist, we can create it!
            if ( [restOfPath count] == 1 ) {
     
                NSMutableDictionary * restDictionary = [self valueForKey:first];
                if ( restDictionary ) {
                    restDictionary = [restDictionary mutableCopy];
                    [self setValue:restDictionary forKey:first];
                    return [restDictionary setValue:value forPath:restOfPath];
                }
                else {
                    // doesn't exist, so lets create it
                    restDictionary = [[NSMutableDictionary alloc] init];
                    [self setValue:restDictionary forKey:first];
                    return [restDictionary setValue:value forPath:restOfPath];
                }
            }
            else {
                // There is more to the path, so keep going
                return [[self valueForKey:first] setValue:value forPath:restOfPath];
            }
        }
    }
}

@end
