//
//  GKManagedDriver.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKManagedDriver.h"
#import "GKManagedDebt.h"
#import "GKManagedDrive.h"


@implementation GKManagedDriver

@dynamic color;
@dynamic name;
@dynamic visited;
@dynamic drove;
@dynamic hiked;
@dynamic isOwed;
@dynamic shouldPay;



-(NSNumber *) recursivelyEliminateDebtCycelsByDebt:(GKManagedDebt *)debt withMaximum:(NSNumber *) max{
    
    GKManagedDriver *driver=debt.owedTo;
    NSNumber *toRemove=[NSNumber numberWithFloat:0];
    
    if (!([driver.color intValue]==1)) {    //if target of debt is not of color 1,
        
        //!!amount to remove = maximum of recursive call on following debts (zero if none) (because there is at most 1 cycle!!!!!)
        
        //!!find who driver owes
        
        //prepare request
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
        request.predicate=[NSPredicate predicateWithFormat:@"owedBy= %@",driver];
        request.sortDescriptors = NULL;
        
        //apply fetch
        NSError *error = nil;
        NSMutableArray *driverDebts = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
        if (driverDebts == nil) {
            // Handle the error.
            NSLog(@"error in fetch request");
        }         
        
        /* why would i want to remove these elements??
         //!!remove from fetch elements that are not participants
         NSMutableSet *debtsToRemove;
         for (GKManagedDebt *followingDebt in driverDebts) {
         if (![self.participants containsObject:followingDebt.owedTo])
         [debtsToRemove addObject:driverDebts];
         }
         for (GKManagedDebt *followingDebt in debtsToRemove) {
         [driverDebts removeObject:followingDebt];
         }
         */
        
        //!!if no outgoing debts, there's no cycle. return zero
        if ([driverDebts count]==0) {
            NSLog(@"no following debts found, returning zero");
            return [NSNumber numberWithFloat:0];  
        }
        
        
        //!!find if any of the debts that driver owes complete a cycle
        for (GKManagedDebt *followingDebt in driverDebts) {
            
            //the new maximum is smaller if followingDebt sum is small
            NSNumber *newMax=[NSNumber numberWithFloat:MIN([max floatValue], [followingDebt.sum floatValue])];
            
            //recursive call
            toRemove=[self recursivelyEliminateDebtCycelsByDebt:followingDebt withMaximum:newMax];
            
            if (!([toRemove floatValue]==0)) break;//we found somthing to remove!
        }
    } else {//!!else (color *is* 1), amount to remove = minimum between given maximum and amount of debt
        NSLog(@"cycle found");
        toRemove=[NSNumber numberWithFloat: MIN([max floatValue], [debt.sum floatValue])];
    }
    
    //!!remove amount to remove, and if no debt left, remove debt. 
    if ([toRemove  isEqualToNumber: debt.sum]) {
        [self.managedObjectContext deleteObject:debt];        
    } else if ([toRemove floatValue]>0)  
        debt.sum=[NSNumber numberWithFloat:[debt.sum floatValue]-[toRemove floatValue]];
    
    
    //!!return amount to remove
    return toRemove;
}



-(void) eliminateDebtCycelsByDebt:(GKManagedDebt *)debt{
    
    //color bottom of debt with color 1
    GKManagedDriver *initialDriver=debt.owedBy;
    initialDriver.color=[NSNumber numberWithFloat:1.0];
    
    //remove debt using recursive call, reiterate if cycle was found but debt was not eliminated
    float originalDebt, debtReducedBy;
    do {
        originalDebt=[debt.sum floatValue];
        debtReducedBy=[[self recursivelyEliminateDebtCycelsByDebt:debt withMaximum:debt.sum] floatValue];
        
        NSLog(@"original debt of %f reduced by %f", originalDebt, debtReducedBy);
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) NSLog(@"trouble saving to DB!");
    } while ((debtReducedBy >0) && (debtReducedBy<originalDebt));
    
    
    //recolor to 0
    initialDriver.color=0;
    
}

-(void) addDebtTo:(GKManagedDriver *)driver onAmount:(NSNumber *) sum{
    //convert negative sums to positive sums
    float  floatSum=[sum floatValue];
    if (floatSum<0) {
        [driver addDebtTo:self onAmount:[NSNumber numberWithFloat:(-floatSum)]];
        return;
    }
    
    GKManagedDebt *currentDebt=[self  currentDebtTo:driver];
    if (!currentDebt) {
        //NSLog(@"no previous debt found");
        currentDebt = (GKManagedDebt *)[NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:self.managedObjectContext];
        currentDebt.owedBy=self;
        currentDebt.owedTo=driver;
        currentDebt.sum= [NSNumber numberWithFloat:
                          ([currentDebt.sum floatValue]+[sum floatValue])];
    } else {
        
        NSLog(@"found existing debt of %f from %@ to %@",  [currentDebt.sum floatValue],currentDebt.owedBy.name, currentDebt.owedTo.name);
        currentDebt.sum= [NSNumber numberWithFloat:
                          ([currentDebt.sum floatValue]+[sum floatValue])];
    }
    NSError *error;
    if (![self.managedObjectContext save:&error]) NSLog(@"problem saving to db");
    //NSLog(@"now %@ owes %@ to %@",current.owedBy.name, current.sum, current.owedTo.name);
    
    //if this creat a cycle, eliminate it
    [self eliminateDebtCycelsByDebt:currentDebt];
}

-(GKManagedDebt *) currentDebtTo:(GKManagedDriver *) driver{
    NSLog(@"looking for debt of %@ to %@", self.name,driver.name);
    
    //prepare request
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
    request.predicate=[NSPredicate predicateWithFormat:@" (owedTo=%@) AND (owedBy= %@)",driver, self];
    request.sortDescriptors = NULL;
    
    //apply fetch
    NSError *error = nil;
    NSArray *debtsOwed = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (debtsOwed == nil) {
        // Handle the error.
        NSLog(@"error in fetch request");
    }
    
    if ([debtsOwed count]>1) NSLog(@"error - multiple parallel debts");
    //NSLog(@"directly, found %d debts", [debtsOwed count]);
    return [debtsOwed lastObject];
    
}


@end
