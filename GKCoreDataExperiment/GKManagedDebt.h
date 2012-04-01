//
//  GKManagedDebt.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GKManagedDriver;

@interface GKManagedDebt : NSManagedObject

@property (nonatomic, retain) NSNumber * sum;
@property (nonatomic, retain) GKManagedDriver *owedBy;
@property (nonatomic, retain) GKManagedDriver *owedTo;

@end
