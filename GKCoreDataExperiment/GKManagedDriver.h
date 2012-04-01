//
//  GKManagedDriver.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GKManagedDebt, GKManagedDrive;

@interface GKManagedDriver : NSManagedObject

@property (nonatomic, retain) NSNumber * color;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * visited;
@property (nonatomic, retain) NSSet *drove;
@property (nonatomic, retain) NSSet *hiked;
@property (nonatomic, retain) NSSet *isOwed;
@property (nonatomic, retain) NSSet *shouldPay;
@end

@interface GKManagedDriver (CoreDataGeneratedAccessors)

- (void)addDroveObject:(GKManagedDrive *)value;
- (void)removeDroveObject:(GKManagedDrive *)value;
- (void)addDrove:(NSSet *)values;
- (void)removeDrove:(NSSet *)values;

- (void)addHikedObject:(GKManagedDrive *)value;
- (void)removeHikedObject:(GKManagedDrive *)value;
- (void)addHiked:(NSSet *)values;
- (void)removeHiked:(NSSet *)values;

- (void)addIsOwedObject:(GKManagedDebt *)value;
- (void)removeIsOwedObject:(GKManagedDebt *)value;
- (void)addIsOwed:(NSSet *)values;
- (void)removeIsOwed:(NSSet *)values;

- (void)addShouldPayObject:(GKManagedDebt *)value;
- (void)removeShouldPayObject:(GKManagedDebt *)value;
- (void)addShouldPay:(NSSet *)values;
- (void)removeShouldPay:(NSSet *)values;

@end
