//
//  State.m
//  StoreExample
//
//  Created by David House on 8/18/12.
//  Copyright (c) 2012 David House. All rights reserved.
//

#import "State.h"
#import "NSObject+ValueForPath.h"

@implementation State

#pragma mark - MambaObjectProperties

- (NSString *)mambaObjectKey {
    return self.abbreviation;
}

- (NSString *)mambaObjectTitle {
    return self.name;
}

- (NSString *)mambaObjectForeignKey {
    return [self.abbreviation substringToIndex:1];
}

- (NSNumber *)mambaObjectOrderNumber {
    return [NSNumber numberWithInt:[self.population intValue]];
}

#pragma mark - Public Methods
+ (void)loadTestStates {
    
    NSData *rawData = nil;
    
    for (NSBundle *bundle in [NSBundle allBundles]) {
        
        NSString *dataPath = [bundle pathForResource:@"States" ofType:@"json"];
        if ( dataPath ) {
            NSLog(@"dataPath: %@",dataPath);
            rawData = [NSData dataWithContentsOfFile:dataPath];
        }
    }
    
    if ( rawData ) {
        
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:&error];
        if ( jsonObject == nil ) {
            NSLog(@"error loading json: %@",[error localizedDescription]);
        }
        
        // We assume the top level is an array
        for ( id doc in jsonObject ) {
            
            State *newState = [[State alloc] init];
            newState.name = [doc valueForPath:@[@"attributes",@"name"]];
            newState.abbreviation = [doc valueForPath:@[@"attributes",@"abbreviation"]];
            newState.population = [doc valueForPath:@[@"attributes",@"population"]];
            newState.squareMiles = [doc valueForPath:@[@"attributes",@"square-miles"]];
            newState.capital = [doc valueForPath:@[@"attributes",@"capital"]];
            newState.mostPopulousCity = [doc valueForPath:@[@"attributes",@"most-populous-city"]];
            [newState MB_save];
        }
    }
}

@end
