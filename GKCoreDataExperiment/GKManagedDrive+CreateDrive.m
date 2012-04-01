//
//  NSObject+CreateDriver.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKManagedDrive+CreateDrive.h"

@implementation GKManagedDrive (CreateDriver)

+(GKManagedDrive *) newDriveWithDriver:(GKManagedDriver *) driver hikers:(NSSet *)participants date:(NSDate *)date occured:(BOOL) didOccur inContext:(NSManagedObjectContext *) context{

    GKManagedDrive *newDrive=(GKManagedDrive *) [NSEntityDescription insertNewObjectForEntityForName:@"Drive" inManagedObjectContext:context];

    newDrive.driver=driver;
    newDrive.hiker=participants;
    newDrive.date=date;
    newDrive.occured=[NSNumber numberWithBool: didOccur];
    newDrive.length= [NSNumber numberWithFloat:1.0];
    newDrive.dateCreated=[NSDate date];
    
    [context insertObject:newDrive];
    
    NSError *error;
    if (![context save:&error]) NSLog(@"somthin wrong with saving drive");
    
    return newDrive;

}


@end
