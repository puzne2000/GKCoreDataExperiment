//
//  GKDateChooser.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GKDateChooserDelegateProtocol <NSObject>

-(void) setDate:(NSDate *) date;

@end

@interface GKDateChooser : UIViewController

@property (weak, nonatomic) id <GKDateChooserDelegateProtocol> delegate;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;


- (IBAction)done:(id)sender;

@end
