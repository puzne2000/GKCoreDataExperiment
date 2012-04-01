//
//  NSObject+CreateDriver.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GKManagedDrive.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface GKManagedDrive(CreateDriver)

+(GKManagedDrive *) newDriveWithDriver:(GKManagedDriver *) driver hikers:(NSSet *)participants date:(NSDate *)date occured:(BOOL) didOccur inContext:(NSManagedObjectContext *) context;

@end
