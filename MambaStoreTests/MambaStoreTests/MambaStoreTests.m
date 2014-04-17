//
//  MambaStoreTests.m
//  MambaStoreTests
//
//  Created by David House on 9/27/13.
//
//

#import <XCTest/XCTest.h>
#import "MambaStore.h"
#import "State.h"
#import "NSObject+MambaObject.h"
#import "ParentObject.h"
#import "ChildObject.h"
#import "SelfCodedObject.h"

@interface MambaStoreTests : XCTestCase

@end

@implementation MambaStoreTests

- (void)setUp
{
    [super setUp];
    NSLog(@"=== setUp ===");
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [MambaStore removeStore];
    [MambaStore openStore];
    [State loadTestStates];
//    [MambaStore replaceCollection:@"State" withResource:@"States" ofType:@"json" usingClass:[State class]];
}

- (void)tearDown
{
    NSLog(@"=== tearDown ===");
    [MambaStore closeStore];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSaveAndLoadByID {
    
    State *aState = [[State alloc] init];
    aState.name = @"TestState";
    aState.abbreviation = @"TestAbbreviation";
    [aState MB_save];
    
    NSString *sID = [aState MB_objID];
    State *bState = [State MB_loadWithID:sID];
    XCTAssertNotNil(bState, @"State is nil, why didn't it find it?");
    XCTAssertTrue([aState.name isEqualToString:bState.name], @"Names don't match");
    XCTAssertTrue([aState.abbreviation isEqualToString:bState.abbreviation], @"Abbreviations don't match");
    XCTAssertTrue([[bState MB_objID] isEqualToString:sID], @"ObjectIDs don't match, whats up with that?");
}

- (void)testFindAll {

    NSArray *allStates = [State MB_findAll];
    XCTAssertNotNil(allStates, @"findAll returned nil");
    XCTAssertTrue([allStates count] == 50, @"Number of states was %ld instead of 50!",[allStates count]);
    
    // Make sure all states are properly dehydrated
    for ( State *oneState in allStates ) {
        
        NSLog(@"found state: %@ %@",oneState.abbreviation,oneState.name);
        XCTAssertNotNil(oneState.name, @"Found a state with a nil name, should have been set");
        XCTAssertNotNil(oneState.abbreviation, @"Found a state with a nil abbreviation, should have been set");
        XCTAssertNotNil(oneState.population, @"Found a state with a nil population, should have been set");
        XCTAssertNotNil(oneState.squareMiles, @"Found a state with a nil squareMiles, should have been set");
        XCTAssertNotNil(oneState.capital, @"Found a state with a nil capital, should have been set");
        XCTAssertNotNil(oneState.mostPopulousCity, @"Found a state with a nil mostPopulousCity, should have been set");
    }
}

- (void)testNewDocumentWithProperties {
    
    State *newState = [[State alloc] init];
    newState.abbreviation = @"NXX";
    newState.name = @"NEW STATE";
    newState.capital = @"A CAPITAL";
    [newState MB_save];
    
    State *savedState = [State MB_findWithKey:@"NXX"];
    XCTAssertNotNil(savedState, @"state not found");
    XCTAssertTrue([savedState.abbreviation isEqualToString:newState.abbreviation], @"abbreviation are different");
    XCTAssertTrue([savedState.name isEqualToString:newState.name], @"names are different");
    XCTAssertTrue([savedState.capital isEqualToString:@"A CAPITAL"], @"capitals are different, should be A CAPITAL, was %@",savedState.capital);
}

- (void)testFindByKey {
    
    State *georgia = [State MB_findWithKey:@"GA"];
    XCTAssertNotNil(georgia, @"Georgia not found");
    XCTAssertNotNil(georgia.abbreviation, @"abbreviation is nil");
    XCTAssertTrue([georgia.name isEqualToString:@"GEORGIA"], @"name is not GEORGIA");
}

- (void)testFindWithTitle {
    
    NSArray *found = [State MB_findWithTitle:@"GEORGIA"];
    XCTAssertTrue([found count] == 1, @"Should have found 1 state, but found %ld instead",[found count]);
    State *georgia = found[0];
    XCTAssertNotNil(georgia, @"Georgia not found");
    XCTAssertNotNil(georgia.abbreviation, @"abbreviation is nil");
    XCTAssertTrue([georgia.name isEqualToString:@"GEORGIA"], @"Name should be GEORGIA, it is not!");
}

- (void)testFindInTitle {
    
    NSArray *found = [State MB_findInTitle:@"IN"];
    XCTAssertTrue([found count] >= 1, @"Should have found 1 state, but found %ld instead",[found count]);
}

- (void)testDelete {

    
    State *existing = [State MB_findWithKey:@"GA"];
    XCTAssertNotNil(existing, @"georgia not found");
    [existing MB_delete];

    State *savedState = [State MB_findWithKey:@"GA"];
    XCTAssertNil(savedState, @"deleted georgia but it is still here!");
}

- (void)testEmptyCollection {
    
    [State MB_deleteAll];
    NSArray *allStates = [State MB_findAll];
    XCTAssertNotNil(allStates, @"findAll returned nil");
    XCTAssertTrue([allStates count] == 0, @"Number of states was %ld instead of 0!",[allStates count]);
}

- (void)testFindAndUpdate {
    
    State *existing = [State MB_findWithKey:@"GA"];
    XCTAssertNotNil(existing, @"georgia not found");
    
    existing.capital = @"MY HOUSE";
    [existing MB_save];
    
    State *savedState = [State MB_findWithKey:@"GA"];
    XCTAssertTrue([savedState.capital isEqualToString:@"MY HOUSE"], @"capitals are different" );
}

- (void)testFindWithForeignKey {
    
    NSArray *existing = [State MB_findWithForeignKey:@"G"];
    XCTAssertNotNil(existing, @"No states found with foreign key of G");
    XCTAssertTrue([existing count] == 1, @"Should have returned 1 state, but didn't");
    
    State *first = [existing objectAtIndex:0];
    XCTAssertTrue([first.name isEqualToString:@"GEORGIA"], @"name is not GEORGIA");
}

- (void)testOrderNumber {
    
    NSArray *ordered = [State MB_findInTitle:@"NEW"];
    XCTAssertNotNil(ordered, @"List of states was nil");
    XCTAssertTrue([ordered count] == 4, @"Didn't return 4 states!");
    State *check = [ordered objectAtIndex:0];
    XCTAssertTrue([check.name isEqualToString:@"NEW HAMPSHIRE"],@"First state is wrong");
    check = [ordered objectAtIndex:1];
    XCTAssertTrue([check.name isEqualToString:@"NEW MEXICO"],@"First state is wrong");
    check = [ordered objectAtIndex:2];
    XCTAssertTrue([check.name isEqualToString:@"NEW JERSEY"],@"First state is wrong");
    check = [ordered objectAtIndex:3];
    XCTAssertTrue([check.name isEqualToString:@"NEW YORK"],@"First state is wrong");
}

- (void)testCreateTime {
    
    NSArray *first10 = [State MB_createdLeastRecent:10];
    XCTAssertNotNil(first10, @"Least recent result is nil, should have returned some rows");
    XCTAssertTrue([first10 count] == 10, @"Should have returned 10 rows, but returned %ld instead",[first10 count]);
    State *check = [first10 objectAtIndex:0];
    XCTAssertTrue([check.name isEqualToString:@"ALABAMA"],@"First state is wrong, should be ALABAMA, was %@",check.name);
    
    
    NSArray *last10 = [State MB_createdMostRecent:10];
    XCTAssertNotNil(last10, @"Most recent result is nil, should have returned some rows");
    XCTAssertTrue([last10 count] == 10, @"Should have returned 10 rows, but returned %ld instead",[last10 count]);
    check = [last10 objectAtIndex:0];
    XCTAssertTrue([check.name isEqualToString:@"WYOMING"],@"First state is wrong, should be WYOMING, was %@",check.name);
}

- (void)testUpdateTime {
    
    State *existing = [State MB_findWithKey:@"GA"];
    XCTAssertNotNil(existing, @"georgia not found");
    existing.capital = @"MY HOUSE";
    NSDate *firstUpdateTime = [existing MB_updateTime];
    [existing MB_save];
    
    State *savedState = [State MB_findWithKey:@"GA"];
    XCTAssertTrue([savedState.capital isEqualToString:@"MY HOUSE"], @"capitals are different" );
    NSDate *secondUpdateTime = [savedState MB_updateTime];
    XCTAssertTrue( [firstUpdateTime compare:secondUpdateTime] == NSOrderedAscending, @"Update times aren't in order %@ %@",firstUpdateTime,secondUpdateTime );
    
    NSArray *lastUpdated = [State MB_updatedMostRecent:1];
    XCTAssertNotNil(lastUpdated, @"updated most recent returned nil, should be an array");
    XCTAssertTrue([lastUpdated count] == 1, @"returned %ld records, but should have been 1",[lastUpdated count]);
    State *firstState = [lastUpdated objectAtIndex:0];
    XCTAssertTrue([firstState.capital isEqualToString:@"MY HOUSE"], @"capitals are different" );
}

- (void)testNotifications {
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kMambaStoreNotification object:[State class] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSLog(@"notification info: %@",note.userInfo);
        
        // TODO: Need to figure out a good way to test to make sure we get the correct notifications and that
        // they are in the correct order.
        
        dispatch_semaphore_signal(sema);
    }];
    
    State *newState = [[State alloc] init];
    newState.abbreviation = @"NXX";
    newState.name = @"NEW STATE";
    newState.capital = @"A CAPITAL";
    [newState MB_save];
    
    newState.capital = @"A NEW CAPITAL";
    [newState MB_save];
    
    [newState MB_delete];
    
    while ( dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testChildCollections
{
    ParentObject *firstParent = [[ParentObject alloc] init];
    firstParent.parentName = @"first";
    
    ChildObject *firstChild = [[ChildObject alloc] init];
    firstChild.childName = @"firstC";
    [firstParent.children addObject:firstChild];

    ChildObject *secondChild = [[ChildObject alloc] init];
    secondChild.childName = @"secondC";
    [firstParent.children addObject:secondChild];

    [firstParent MB_save];
    
    NSArray *allParents = [ParentObject MB_findAll];
    XCTAssertTrue(allParents.count == 1, @"ParentObject not saved correctly, should be 1 but found %lu",allParents.count);
    
    NSArray *allChildren = [ChildObject MB_findAll];
    XCTAssertTrue(allChildren.count == 2, @"ChildObject not saved correctly, should be 2 but found %lu",allChildren.count);
    XCTAssertNotNil([allChildren[0] mambaObjectForeignKey], @"ChildObject 0 had no foreign key");
    XCTAssertNotNil([allChildren[1] mambaObjectForeignKey], @"ChildObject 0 had no foreign key");
    
    ParentObject *aParent = allParents[0];
    XCTAssertTrue(aParent.children.count == 2, @"Parent doesn't have 2 children, only has %lu",aParent.children.count);
    for ( ChildObject *child in aParent.children ) {
        NSLog(@"child: %@",child.childName);
    }
    
    [firstParent MB_delete];
    
    NSArray *remainingChildren = [ChildObject MB_findAll];
    XCTAssertTrue(remainingChildren.count == 0, @"ChildObjects didn't get deleted, there are %lu left",remainingChildren.count);
}

- (void)testSelfEncoding
{
    SelfCodedObject *sco = [[SelfCodedObject alloc] init];
    sco.title = @"selfie";
    sco.frame = CGRectMake(10, 20, 30, 40);
    [sco MB_save];
    
    NSArray *objects = [SelfCodedObject MB_findAll];
    XCTAssertTrue(objects.count == 1, @"Should have found 1 self coded object, but found %lu instead",objects.count);
    SelfCodedObject *first = objects[0];
    XCTAssertTrue([first.title isEqualToString:@"selfie"], @"title was not the same, it was %@",first.title);
    XCTAssertTrue(first.frame.origin.x == 10, @"frame X was incorrect, was %f instead",first.frame.origin.x);
    XCTAssertTrue(first.frame.origin.y == 20, @"frame Y was incorrect, was %f instead",first.frame.origin.y);
    XCTAssertTrue(first.frame.size.width == 30, @"frame WIDTH was incorrect, was %f instead",first.frame.size.width);
    XCTAssertTrue(first.frame.size.height == 40, @"frame HEIGHT was incorrect, was %f instead",first.frame.size.height);
}

- (void)testInsertSpeed
{
    for ( int i =0; i < 10000; i++ ) {
        ParentObject *newObj = [[ParentObject alloc] init];
        [newObj MB_save];
    }
}

- (void)testCount
{
    NSNumber *stateCount = [State MB_countAll];
    XCTAssertTrue([stateCount intValue] == 50, @"State count wasn't 50 like it was supposed to be");
}

- (void)testCountInKey
{
    NSNumber *gaCount = [State MB_countWithKey:@"GA"];
    XCTAssertTrue([gaCount intValue] == 1, @"Should have 1 state with key of GA");
    NSNumber *gCount = [State MB_countLikeKey:@"G"];
    XCTAssertTrue([gCount intValue] == 1, @"Should have 1 state with key like G");
}

- (void)testCountInTitle
{
    NSNumber *gaCount = [State MB_countWithTitle:@"GEORGIA"];
    XCTAssertTrue([gaCount intValue] == 1, @"Should have 1 state with title of Georgia");
    NSNumber *newCount = [State MB_countLikeTitle:@"NEW"];
    XCTAssertTrue([newCount intValue] == 4,@"Should have 4 states with NEW in the title");
}

- (void)testCountInForeignKey
{
    NSNumber *gCount = [State MB_countWithForeignKey:@"G"];
    XCTAssertTrue([gCount intValue] == 1, @"Should have 1 state with G foreign key");
    gCount = [State MB_countLikeForeignKey:@"G"];
    XCTAssertTrue([gCount intValue] == 1, @"Should have 1 state with G foreign key");
}

- (void)testCountRanges
{
    NSNumber *orderCount = [State MB_countOrderedFrom:@1000000 to:@2000000];
    XCTAssertTrue([orderCount intValue] == 7, @"There should be 7 states between 1000000 and 2000000 population");
    
    NSNumber *createCount = [State MB_countCreatedFrom:[NSDate dateWithTimeInterval:-50000 sinceDate:[NSDate date]] to:[NSDate date]];
    XCTAssertTrue([createCount intValue] == 50, @"There should be 50 states created today");
    
    NSNumber *updateCount = [State MB_countUpdatedFrom:[NSDate dateWithTimeInterval:-50000 sinceDate:[NSDate date]] to:[NSDate date]];
    XCTAssertTrue([updateCount intValue] == 50, @"There should be 50 states updated today");
}

@end
