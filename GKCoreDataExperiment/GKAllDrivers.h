//
//  GKAllDrivers.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/30/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

@interface GKAllDrivers : CoreDataTableViewController

//@property (nonatomic, strong) UIManagedDocument *database;  // Model is a Core Data database 

@property (strong, nonatomic) NSManagedObjectContext *dbContext;

- (IBAction)addDriverItem:(UIBarButtonItem *)sender;



@end
