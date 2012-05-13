//
//  GKHistoryVCViewController.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 5/12/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKHistoryVCViewController.h"
#import "GKCarpoolDB.h"
#import "GKManagedDrive.h"
#import "GKManagedDriver.h"
#import "GKDriveCell.h"
#import <MessageUI/MessageUI.h>


@interface GKHistoryVCViewController ()

@end

@implementation GKHistoryVCViewController

@synthesize dbContext=_dbContext;


- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Drive"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    // no predicate because we want ALL the drivers
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.dbContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

#pragma mark - email button

- (NSString *) driveReport{
    
    static NSDateFormatter *_dateFormatter;
    if (!_dateFormatter) {
        _dateFormatter=[[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    NSString *report=[NSString string];
    
    NSArray *selectedCellPaths=self.tableView.indexPathsForSelectedRows;
    for (NSIndexPath *indexPath in selectedCellPaths) {
        GKManagedDrive *drive= [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        report=[report stringByAppendingString:[_dateFormatter stringFromDate:drive.date]];
        
        report=[report stringByAppendingFormat:@"\n\nDriver: "];
        if (drive.driver) report=[report stringByAppendingString:drive.driver.name];
        
        report=[report stringByAppendingFormat:@"\n\n Hikers: \n"];
        for (GKManagedDriver *hiker in drive.hiker) {
            report=[report stringByAppendingFormat:@"    %@\n",hiker.name];
        }
        report=[report stringByAppendingFormat:@"\n\n"];
    }
    return report;
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)emailButtonPressed:(UIBarButtonItem *)sender {
    {
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            
            mailer.mailComposeDelegate = (id) self;
            
            [mailer setSubject:@"A carpool history report, braught to you by Kindler Insdustries"];
            
            /*
             NSArray *toRecipients = [NSArray arrayWithObjects:@"fisrtMail@example.com", @"secondMail@example.com", nil];
             [mailer setToRecipients:toRecipients];
             
             
             UIImage *myImage = [UIImage imageNamed:@"mobiletuts-logo.png"];
             NSData *imageData = UIImagePNGRepresentation(myImage);
             [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"mobiletutsImage"]; 
             */
            
            NSString *emailBody = [self driveReport];
            [mailer setMessageBody:emailBody isHTML:NO];
            
            [self presentModalViewController:mailer animated:YES];
            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                            message:@"Your device doesn't support the composer sheet"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            alert=nil;
        }
        
    }
}




#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    GKManagedDrive *current_drive = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return (52.0+(1+[current_drive.hiker count])*22.0);
}

                
                
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Drive Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
   GKManagedDrive *current_drive = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([cell respondsToSelector:@selector(drive)]) ((GKDriveCell *)cell).drive=current_drive;
    //cell.textLabel.text =current_drive.driver.name;
    return cell;
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //self.navigationController.toolbarHidden=NO;
    //get global database context   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseReady:) 
                                                 name:@"Database Ready"
                                               object:nil];
    
    self.dbContext=[GKCarpoolDB sharedContext];
    if ([GKCarpoolDB globalDBIsReady]) [self databaseReady:nil];
    /*   
     NSLog(@"trying the parse thing");
     PFObject *testObject = [PFObject objectWithClassName:@"TestObject"];
     [testObject setObject:@"bar" forKey:@"foo"];
     [testObject save];
     */
}

- (void)  databaseReady:(NSNotification *) notification {
    NSLog(@"got message that db is ready");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setupFetchedResultsController];
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem; 
    
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}





- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //self.navigationController.toolbarHidden=YES;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

@end