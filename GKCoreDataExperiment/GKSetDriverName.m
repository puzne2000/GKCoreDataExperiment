//
//  GKSetDriverName.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKSetDriverName.h"

@implementation GKSetDriverName
@synthesize nameField=_nameField;


@synthesize driver=_driver;

-(void) setDriverName:(NSString *)name{
    self.driver.name= name;
    NSError *error;
    [self.driver.managedObjectContext save:&error];
    if (error) NSLog(@"DB error!");

}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
        NSLog(@"text sould return");
     return YES;
 }

- (IBAction)done:(id)sender {
    if (self.nameField.text.length>0)
        [self setDriverName:self.nameField.text];
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"init with name %@", nibNameOrNil);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void) viewWillAppear:(BOOL)animated{
    NSLog(@"view willlll appear");
    self.nameField.delegate = (id <UITextFieldDelegate>) self;
    self.nameField.placeholder=self.driver.name;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [self setNameField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
