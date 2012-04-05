//
//  GKNewDriveController.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKDebtsViewController.h"

#import "GKDateChooser.h"
#import "GKCarpoolDB.h"
#import "GKManagedDrive+CreateDrive.h"
#import <CoreData/CoreData.h>
#import "GKManagedDriver.h"
#import "GKManagedDebt.h"

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
@synthesize populated;
//@synthesize participatnsDriverButtonLabel = _participatnsDriverButtonLabel;
-(NSManagedObjectContext *) dbContext{
    return _dbContext;
}

@synthesize driver=_driver;



#pragma mark - debt and driver suggestions

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


-(GKManagedDebt *) currentDebtOf:(GKManagedDriver *) hiker to:(GKManagedDriver *) driver{
    NSLog(@"looking for debt of %@ to %@", hiker.name,driver.name);

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
    if ([debtsOwed count]>1) NSLog(@"error - multiple parallel debts");
    //NSLog(@"directly, found %d debts", [debtsOwed count]);
    return [debtsOwed lastObject];
    
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

-(void) makeDesignatedDriverOfCellIndex:(NSIndexPath *)indexPath forParticipants:(NSArray *) participants{
    
    [self clearTable];
    
    GKManagedDriver *driver=[self.participants objectAtIndex:indexPath.row];
     UITableViewCell *cell=[self.tableView cellForRowAtIndexPath:indexPath];
    //## GKManagedDriver *designatedDriver= [self.tableView   objectAtIndexPath:indexPath];

    for (GKManagedDriver *participant in participants) {
        NSLog(@"participant is %@", participant.name);
        NSIndexPath *indexOfParticipant=[self indexForDriver:participant];
        //UITableViewCell *participantCell= [self.tableView cellForRowAtIndexPath:indexOfParticipant];
        NSNumber *sum=[self currentDebtOf:participant to:driver].sum;
        NSString *string;
        UIColor *color;
        if (sum) {
            string=[NSString stringWithFormat:@"I owe %@  %@ trips", driver.name,sum];
            color=[UIColor redColor];
            
        } else {
            
            sum=[self currentDebtOf:driver to:participant].sum;
            if (!sum) sum=[NSNumber numberWithFloat:0.0];
            string=[NSString stringWithFormat:@"%@ owes me %@ trips", driver.name, sum];
            color=[UIColor greenColor];
        }
        [self writeOnCell:indexOfParticipant string:string withColor:color];
            
        [self writeOnCell:indexPath string:@"selected" withColor:[UIColor grayColor]];
    cell.highlighted=YES;
    }
}

//- (IBAction)participantsDriverButtonPressed:(UIButton *)sender{
    /*
    if (self.myState==gkSelectingParticipants){
        
        if ([self.participants count]>0) {
            self.myState=gkSelectingDriver;
            self.participatnsDriverButtonLabel.text=@"choose driver";
            self.driver=self.computeSuggestedDriver;
            NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
            [self makeDesignatedDriverOfCellIndex:currentDriverPath forParticipants:self.participants];
            //UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
            //currentDriverCell.detailTextLabel.text=@"Designated Driver";
        }
    } else if (self.myState==gkSelectingDriver) {
        
        //add trip and compute debts
        //NSLog(@"completed selecting driver");
        
        [self.participants removeObject:self.driver];//participant are now just hikers

        
        self.lastDriveCreated= [GKManagedDrive  newDriveWithDriver:self.driver hikers:self.participants date:self.dateForDrive occured:YES inContext:self.dbContext];
        [self.dbContext insertObject:self.lastDriveCreated];
        
        //NSLog(@"added new drive %@, now computing new debts",self.lastDriveCreated);
        [self recomputeDebtWithDrive:self.lastDriveCreated];
        
        
        self.myState=gkDone;
        self.participatnsDriverButtonLabel.text=@"Done! Trip added...";

        NSError *error;

        if (![self.dbContext save:&error]) NSLog(@"error saving");
        
    } else if (self.myState==gkDone) {
        NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
        UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
        currentDriverCell.detailTextLabel.text=@"---";//## should zero all cells!!
        for (GKManagedDriver *driver in self.participants) {
                NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:driver];
                UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
                currentDriverCell.detailTextLabel.text=@"---";
        }
        
        NSLog(@"new drive beginning");
        self.participatnsDriverButtonLabel.text=@"Choose Participants and Date";
        self.myState=gkSelectingParticipants;
        [self.tableView reloadData];
        self.participants=NULL;
        self.driver=NULL;
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext=NO;
       
        
    }
}*/

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




#pragma mark - from photographer table view...

//remember to setupFetchedResultsController
/*
- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    // no predicate because we want ALL the drivers
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.dbContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    NSLog(@"results controller %@", self.fetchedResultsController);
    NSLog(@"context class: %@", [self.dbContext class]);
}
*/





// Override to support editing the table view.
/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        GKManagedDriver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [self.dbContext deleteObject:driver];
        
        
        // Commit the change.
        NSError *error = nil;
        if (![self.dbContext save:&error]) {
            // Handle the error.
        }
        // Update the array and table view.
        //        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}
*/

// 2. Make the database's setter start using it

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"view will appears");
    self.populated=NO;
    [self clearTable];
    
    
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

#pragma mark - Table view data source

/*
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
 {
 #warning Potentially incomplete method implementation.
 // Return the number of sections.
 return 1;
 }
 */

/*
 - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
 {
 #warning Incomplete method implementation.
 // Return the number of rows in the section.
 NSLog(@"section number %@",section);
 return 1;
 }
 */


// 19. Support segueing from this table to any view controller that has a database @property.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"preparing for segue %@",segue.identifier);
    
    
    if ([segue.identifier isEqualToString:@"ChooseDate"]) {
        ((GKDateChooser *)segue.destinationViewController).delegate = (id <GKDateChooserDelegateProtocol>) self;
        
        /*
         if ([segue.identifier isEqualToString:@"ChooseDate"]) {
         NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
         GKManagedDriver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
         GKSetDriverName *destination=segue.destinationViewController;
        destination.driver=driver;
         */
    }
    
    
    /*
     NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
     GKManagedDriver *Driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
     // be somewhat generic here (slightly advanced usage)
     // we'll segue to ANY view controller that has a driver @property
     if ([segue.destinationViewController respondsToSelector:@selector(setDriver:)]) {
     // use performSelector:withObject: to send without compiler checking
     // (which is acceptable here because we used introspection to be sure this is okay)
     [segue.destinationViewController performSelector:@selector(setDriver:) withObject:Driver];
     }
     */
}



/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */




/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

@end

