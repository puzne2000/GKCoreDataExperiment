//
//  GKNewDriveController.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKDebtsViewController.h"

//#import "GKDateChooser.h"
#import "GKCarpoolDB.h"
#import "GKManagedDrive+CreateDrive.h"
#import <CoreData/CoreData.h>
#import "GKManagedDriver.h"
#import "GKManagedDebt.h"
#import <MessageUI/MessageUI.h>

@interface GKDebtsViewController()

@property (strong, nonatomic) GKManagedDriver *driver;
@property (strong, nonatomic) NSMutableArray *participants;
@property (nonatomic) BOOL populated;
@end




@implementation GKDebtsViewController{
}


#pragma mark - synthesizes

@synthesize dbContext=_dbContext;
@synthesize participants=_participants;
@synthesize driver=_driver;
@synthesize populated;

#pragma mark - handling email report

-(NSString *) debtReport{
    NSString *report=[NSMutableString string];
    for (GKManagedDriver *hiker in self.participants) {
        for (GKManagedDriver *driver in self.participants) {
            
            NSNumber *debt=[self currentDebtOf:hiker to:driver].sum;
            if (debt) report=[report stringByAppendingFormat:@"%@ owes %@ drives to %@ \n",hiker.name, debt, driver.name];
            
        }
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


- (IBAction)emailButton:(UIBarButtonItem *)sender {
    {
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            
            mailer.mailComposeDelegate = (id) self;
            
            [mailer setSubject:@"A carpool report, braught to you by Kindler Insdustries"];
            
            /*
            NSArray *toRecipients = [NSArray arrayWithObjects:@"fisrtMail@example.com", @"secondMail@example.com", nil];
            [mailer setToRecipients:toRecipients];
            
            
            UIImage *myImage = [UIImage imageNamed:@"mobiletuts-logo.png"];
            NSData *imageData = UIImagePNGRepresentation(myImage);
            [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"mobiletutsImage"]; 
            */
            
            NSString *emailBody = [self debtReport];
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



#pragma mark - debt 



-(GKManagedDebt *) currentDebtOf:(GKManagedDriver *) hiker to:(GKManagedDriver *) driver{
    //i think if there is no debt nil is returned

    //prepare request
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
    request.predicate=[NSPredicate predicateWithFormat:@" (owedTo=%@) AND (owedBy= %@)",driver, hiker];
    request.sortDescriptors = NULL;
    
    //apply fetch
     NSError *error = nil;
     NSArray * debtsOwed = [[self.dbContext executeFetchRequest:request error:&error] mutableCopy];
    if (debtsOwed == nil) {
        // Handle the error.
        NSLog(@"error in fetch request");
    }
    
    //if ([debtsOwed count]>1) NSLog(@"error - multiple parallel debts");
 
   // if (![debtsOwed lastObject]) NSLog(@"returning nil for currentDebt");
    return [debtsOwed lastObject];//might be nil i think
    
}


#pragma mark - changind states

-(NSIndexPath *) indexForDriver:(GKManagedDriver *) driver {
    if (!self.populated) return nil;
    NSUInteger row=[self.participants indexOfObject:driver];
    NSIndexPath *answer=[NSIndexPath indexPathForRow:row inSection:0];
    return answer;
}

-(void) writeOnCell:(NSIndexPath *)indexPath string:(NSString *)string withColor:(UIColor *)color{
    UITableViewCell *cell=[self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.textColor=color;
    cell.detailTextLabel.text=string;
}


-(void) makeDesignatedDriverOfCellIndex:(NSIndexPath *)indexPath forParticipants:(NSArray *) participants{
    
    GKManagedDriver *driver=[self.participants objectAtIndex:indexPath.row];
     UITableViewCell *cell=[self.tableView cellForRowAtIndexPath:indexPath];
    //## GKManagedDriver *designatedDriver= [self.tableView   objectAtIndexPath:indexPath];

    for (GKManagedDriver *participant in participants) {
        if (!(participant==driver)) {
            
            //NSLog(@"participant is %@", participant.name);
            NSIndexPath *indexOfParticipant=[self indexForDriver:participant];
            UITableViewCell *cellOfParticipat=[self.tableView cellForRowAtIndexPath:indexOfParticipant];
            //UITableViewCell *participantCell= [self.tableView cellForRowAtIndexPath:indexOfParticipant];
            NSNumber *sum=[self currentDebtOf:participant to:driver].sum;
            NSString *string;
            UIColor *color;
            if (sum) {
                string=[NSString stringWithFormat:@"I owe %@  %@ drivess", driver.name,sum];
                color=[UIColor orangeColor];
                
            } else {
                
                sum=[self currentDebtOf:driver to:participant].sum;
                if (!sum){
                    string=@"---";
                    color=[UIColor grayColor];
                } else {
                string=[NSString stringWithFormat:@"%@ owes me %@ drives", driver.name, sum];
                color=[UIColor greenColor];
                }
            }
            [self writeOnCell:indexOfParticipant string:string withColor:color];
            cellOfParticipat.highlighted=NO;
        }
    }
        [self writeOnCell:indexPath string:@"selected" withColor:[UIColor grayColor]];
    cell.highlighted=YES;
}



#pragma mark - Table view changes

-(void) clearTable {
    self.driver=nil;
    for (GKManagedDriver *participant in self.participants) {
        NSIndexPath *indexOfParticipant=[self indexForDriver:participant];
        UITableViewCell *cell=[self.tableView cellForRowAtIndexPath:indexOfParticipant];
        cell.highlighted=NO;
        cell.selected=NO;
        //UITableViewCell *participantCell= [self.tableView cellForRowAtIndexPath:indexOfParticipant];
        [self writeOnCell:indexOfParticipant string:@"---" withColor:[UIColor grayColor]];
    }    
}

-(void) populateTableViewWithParticipants:(NSArray *) participants{
    NSRange range;
    range.location=0;
    range.length=[self.participants count]-1;
    
    
    self.populated=YES;
    //NSIndexSet *indexSet=[NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadData];
    // [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationRight];
    
}


- (void) populateTableView {
    
    //prepareRequest
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    // no predicate because we want ALL the drivers
    
    //apply fetch
    NSError *error = nil;
    self.participants = [[self.dbContext executeFetchRequest:request error:&error] mutableCopy];
    if (!self.participants) NSLog(@"error: %@", error.localizedDescription);
    [self populateTableViewWithParticipants:self.participants];
    
}


/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"preparing for segue %@",segue.identifier);
    if ([segue.identifier isEqualToString:@"ChooseDate"]) {
        ((GKDateChooser *)segue.destinationViewController).delegate = (id <GKDateChooserDelegateProtocol>) self;
    } else NSLog(@"problem: unrecognized segue");

}
*/




#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Driver Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    GKManagedDriver *driver = [self.participants  objectAtIndex:indexPath.row];
    cell.textLabel.text =driver.name;
    return cell;
}

/*
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.driver) {//clean up after old driver
        NSIndexPath *oldIndex=[self indexForDriver:self.driver];
        UITableViewCell *cell=[self.tableView cellForRowAtIndexPath:oldIndex];
        cell.highlighted=NO;
    }
    
    
    //get details of selected cell
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    GKManagedDriver *driver= [self.participants objectAtIndex:indexPath.row];    
              cell.highlighted=YES;
            self.driver=driver;
            [self makeDesignatedDriverOfCellIndex:indexPath forParticipants:self.participants];
    //cell.highlighted=NO;
}
 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return (self.populated?[self.participants count]:0);
}




#pragma mark - view lifecycle that I touched






- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"view will appears");
    [self clearTable];
    self.populated=NO;
   
    
    //get global database context   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseReady:) 
                                                 name:@"Database Ready"
                                               object:nil];

    self.dbContext=[GKCarpoolDB sharedContext];
  if ([GKCarpoolDB globalDBIsReady]) [self databaseReady:nil];//if it is not ready, i will be notified when it is..
}

- (void)  databaseReady:(NSNotification *) notification {
    NSLog(@"got message that db is ready");
    [self populateTableView];
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        NSLog(@"I was inited with style!");
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
    //self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    [self clearTable];
    
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


@end

