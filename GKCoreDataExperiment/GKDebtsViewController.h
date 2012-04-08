//
//  GKNewDriveController.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import <CoreData/CoreData.h>


@interface GKDebtsViewController: UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *dbContext;

- (IBAction)emailButton:(UIBarButtonItem *)sender;

@end
