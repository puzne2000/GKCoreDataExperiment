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


@interface GKNewDriveController :CoreDataTableViewController

//@property (nonatomic, strong) UIManagedDocument *database;  // Model is a Core Data database 
@property (strong, nonatomic) NSManagedObjectContext *dbContext;


@property (weak, nonatomic) IBOutlet UILabel *participatnsDriverButtonLabel;
@property (weak, nonatomic) IBOutlet UIButton *dateLabelButton;
//@property (weak, nonatomic) IBOutlet UIButton *participantsDriverButton;

- (IBAction)participantsDriverButtonPressed:(UIButton *)sender;

@end
