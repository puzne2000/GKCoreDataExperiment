//
//  GKSetDriverName.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GKManagedDriver.h"

@protocol GKNameDelegateProtocol <NSObject>

-(void) setName:(NSString *) name;

@end

@interface GKSetDriverName : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (strong, nonatomic) GKManagedDriver *driver;
- (IBAction)done:(id)sender;

@end
