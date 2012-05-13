//
//  NSObject+CreateDriver.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKManagedDrive+CreateDrive.h"
#import "GKManagedDriver.h"

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

-(NSString *) addNewLineTo:(NSString *) string{
    return [string stringByAppendingString:@"\n"];
}

-(NSString *) textReportNoDate{
    NSString *answer=@"Driver: ";
    if (self.driver.name)
        answer=[answer stringByAppendingString:self.driver.name];
    answer = [self addNewLineTo:answer];
    answer = [self addNewLineTo:answer];
    answer=[answer stringByAppendingString:@"Hikers:"];
    for (GKManagedDriver *hiker in self.hiker) {
        answer=[answer stringByAppendingFormat:@"\n    %@",hiker.name];
    }
    return answer;
}
//-(NSString *) textReport;



@end
