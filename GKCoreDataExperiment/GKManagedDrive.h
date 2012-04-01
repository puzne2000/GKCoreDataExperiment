//
//  GKManagedDrive.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GKManagedDriver;

@interface GKManagedDrive : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * occured;
@property (nonatomic, retain) GKManagedDriver *driver;
@property (nonatomic, retain) NSSet *hiker;
@end

@interface GKManagedDrive (CoreDataGeneratedAccessors)

- (void)addHikerObject:(GKManagedDriver *)value;
- (void)removeHikerObject:(GKManagedDriver *)value;
- (void)addHiker:(NSSet *)values;
- (void)removeHiker:(NSSet *)values;

@end
