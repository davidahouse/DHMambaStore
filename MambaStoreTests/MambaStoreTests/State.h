//
//  State.h
//  StoreExample
//
//  Created by David House on 8/18/12.
//  Copyright (c) 2012 David House. All rights reserved.
//
#import "NSObject+MambaObject.h"

@interface State : NSObject<MambaObjectProperties>

/* {"attributes":{"name":"ALABAMA","abbreviation":"AL","capital":"Montgomery","most-populous-city":"Birmingham","population":"4708708","square-miles":"52423","time-zone-1":"CST (UTC-6)","time-zone-2":"EST (UTC-5)","dst":"YES"}}
*/
 
#pragma mark - Properties
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *abbreviation;
@property (nonatomic,retain) NSString *population;
@property (nonatomic,retain) NSString *squareMiles;
@property (nonatomic,strong) NSString *capital;
@property (nonatomic,strong) NSString *mostPopulousCity;

#pragma mark - Public Methods
+ (void)loadTestStates;

@end
