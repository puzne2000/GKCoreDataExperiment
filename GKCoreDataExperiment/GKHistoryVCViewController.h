//
//  GKHistoryVCViewController.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 5/12/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface GKHistoryVCViewController : CoreDataTableViewController

@property (strong, nonatomic) NSManagedObjectContext *dbContext;
- (IBAction)emailButtonPressed:(id)sender;

@end
