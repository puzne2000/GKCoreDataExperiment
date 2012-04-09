//
//  GKNewDriveController.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/31/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKNewDriveController.h"

#import "GKDateChooser.h"
#import "GKCarpoolDB.h"
#import "GKManagedDrive+CreateDrive.h"
#import <CoreData/CoreData.h>
#import "GKManagedDriver.h"
#import "GKManagedDebt.h"

@interface GKNewDriveController()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDate *dateForDrive;
@property (strong, nonatomic) NSMutableSet *participants;
@property (strong, nonatomic) GKManagedDriver *driver;
@property(strong, nonatomic) GKManagedDrive *lastDriveCreated;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;


- (void)setupFetchedResultsController;

enum mystates {
gkSelectingParticipants,
gkSelectingDriver,
gkDone
};
@property (nonatomic) enum mystates myState;

@end




@implementation GKNewDriveController


#pragma mark - synthesizes

@synthesize dbContext=_dbContext, driveInfoLabel, lastDriveCreated=_lastDriveCreated, myState, participants=_participants, driver=_driver, dateForDrive=_dateForDrive, dateLabelButton=_dateLabelButton;

-(NSManagedObjectContext *) dbContext{
    return _dbContext;
}

-(NSMutableSet *) participants{
    if (!_participants) _participants=[NSMutableSet set];
    return _participants;
}


-(NSDate *) dateForDrive {//default is current date
    if (!_dateForDrive) {
        return [NSDate date];
    }
    return _dateForDrive;
}
-(void) setDateForDrive:(NSDate *)dateForDrive{
    NSLog(@"set date for drive");
    _dateForDrive=(dateForDrive==nil)?self.dateForDrive:dateForDrive;//if argument is nil, set date for today
    //this might not do anything if the dateLabel
    self.dateLabelButton.tintColor=[UIColor redColor];//just a tial
    self.dateLabelButton.titleLabel.text=[self.dateFormatter stringFromDate:dateForDrive];
}

@synthesize dateFormatter=_dateFormatter;
-(NSDateFormatter *) dateFormatter {
    if (!_dateFormatter){
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _dateFormatter;
}

@synthesize cancelButton=_cancelButton;
-(UIBarButtonItem *) cancelButton {
    if (!_cancelButton) {//init cancel button
        _cancelButton=[ [UIBarButtonItem alloc] 
                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                       target:self action:@selector(cancelButtonPressed:)];
    }
    return _cancelButton;
}






#pragma mark - debt and driver suggestions

-(NSNumber *) recursivelyEliminateDebtCycelsByDebt:(GKManagedDebt *)debt withMaximum:(NSNumber *) max{

    GKManagedDriver *driver=debt.owedTo;
    NSNumber *toRemove=[NSNumber numberWithFloat:0];
 
    if (!([driver.color intValue]==1)) {    //if target of debt is not of color 1,
        
        //!!amount to remove = maximum of recursive call on following debts (zero if none) (because there is at most 1 cycle!!!!!)

        //!!find who driver owes
        
        //prepare request
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
        request.predicate=[NSPredicate predicateWithFormat:@"owedBy= %@",driver];
        request.sortDescriptors = NULL;
        
        //apply fetch
        NSError *error = nil;
        NSMutableArray *driverDebts = [[self.dbContext executeFetchRequest:request error:&error] mutableCopy];
        if (driverDebts == nil) {
            // Handle the error.
            NSLog(@"error in fetch request");
        }         
  
        /* why would i want to remove these elements??
        //!!remove from fetch elements that are not participants
        NSMutableSet *debtsToRemove;
        for (GKManagedDebt *followingDebt in driverDebts) {
            if (![self.participants containsObject:followingDebt.owedTo])
                [debtsToRemove addObject:driverDebts];
        }
        for (GKManagedDebt *followingDebt in debtsToRemove) {
            [driverDebts removeObject:followingDebt];
        }
         */
        
        //!!if no outgoing debts, there's no cycle. return zero
        if ([driverDebts count]==0) {
            NSLog(@"no following debts found, returning zero");
            return [NSNumber numberWithFloat:0];  
        }
        
        
        //!!find if any of the debts that driver owes complete a cycle
        for (GKManagedDebt *followingDebt in driverDebts) {
            
            //the new maximum is smaller if followingDebt sum is small
            NSNumber *newMax=[NSNumber numberWithFloat:MIN([max floatValue], [followingDebt.sum floatValue])];
            
            //recursive call
            toRemove=[self recursivelyEliminateDebtCycelsByDebt:followingDebt withMaximum:newMax];
            
            if (!([toRemove floatValue]==0)) break;//we found somthing to remove!
        }
    } else {//!!else (color *is* 1), amount to remove = minimum between given maximum and amount of debt
        NSLog(@"cycle found");
        toRemove=[NSNumber numberWithFloat: MIN([max floatValue], [debt.sum floatValue])];
    }
    
    //!!remove amount to remove, and if no debt left, remove debt. 
    if ([toRemove  isEqualToNumber: debt.sum]) {
        [self.dbContext deleteObject:debt];        
    } else if ([toRemove floatValue]>0)  
        debt.sum=[NSNumber numberWithFloat:[debt.sum floatValue]-[toRemove floatValue]];
    
    
    //!!return amount to remove
    return toRemove;
}



-(void) eliminateDebtCycelsByDebt:(GKManagedDebt *)debt{

    
    //make sure all participants are zero colored
    //## I don't think this is needed..
/*
    for (GKManagedDriver *driver in self.participants) {
        driver.color=0;
    }
 */
    
    //color bottom of debt with color 1
    GKManagedDriver *initialDriver=debt.owedBy;
     initialDriver.color=[NSNumber numberWithFloat:1.0];
    
    //remove debt using recursive call, reiterate if cycle was found but debt was not eliminated
    float originalDebt, debtReducedBy;
    do {
        originalDebt=[debt.sum floatValue];
        debtReducedBy=[[self recursivelyEliminateDebtCycelsByDebt:debt withMaximum:debt.sum] floatValue];
        
        NSLog(@"original debt of %f reduced by %f", originalDebt, debtReducedBy);
        
        NSError *error;
        if (![self.dbContext save:&error]) NSLog(@"trouble saving to DB!");
    } while ((debtReducedBy >0) && (debtReducedBy<originalDebt));
    
    
    //recolor to 0
    initialDriver.color=0;
    
}


-(GKManagedDebt *) currentDebtOf:(GKManagedDriver *) hiker to:(GKManagedDriver *) driver{
    NSLog(@"looking for debt of %@ to %@", hiker.name,driver.name);
    
    //prepare request
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
    request.predicate=[NSPredicate predicateWithFormat:@" (owedTo=%@) AND (owedBy= %@)",driver, hiker];
    request.sortDescriptors = NULL;
    
    //apply fetch
     NSError *error = nil;
    NSArray *debtsOwed = [[self.dbContext executeFetchRequest:request error:&error] mutableCopy];
    if (debtsOwed == nil) {
        // Handle the error.
        NSLog(@"error in fetch request");
    }
    
    if ([debtsOwed count]>1) NSLog(@"error - multiple parallel debts");
    //NSLog(@"directly, found %d debts", [debtsOwed count]);
    return [debtsOwed lastObject];
    
}



-(void) addDebtBy:(GKManagedDriver *)hiker to:(GKManagedDriver *)driver onAmount:(NSNumber *) sum{
    
    //convert negative sums to positive sums
    float  floatSum=[sum floatValue];
    if (floatSum<0) {
        [self addDebtBy:driver to:hiker onAmount:[NSNumber numberWithFloat:(-floatSum)]];
        return;
    }
    
    GKManagedDebt *currentDebt=[self currentDebtOf:hiker to:driver];
    if (!currentDebt) {//## should be done in new category
        //NSLog(@"no previous debt found");
        currentDebt = (GKManagedDebt *)[NSEntityDescription insertNewObjectForEntityForName:@"Debt" inManagedObjectContext:self.dbContext];
        currentDebt.owedBy=hiker;
        currentDebt.owedTo=driver;
        currentDebt.sum= [NSNumber numberWithFloat:
                      ([currentDebt.sum floatValue]+[sum floatValue])];
        if ((!hiker)||(!driver)) NSLog(@"added incomplete debt - serious problem!!!");
    } else {
        
    NSLog(@"found existing debt of %f from %@ to %@",  [currentDebt.sum floatValue],currentDebt.owedBy.name, currentDebt.owedTo.name);
    currentDebt.sum= [NSNumber numberWithFloat:
                  ([currentDebt.sum floatValue]+[sum floatValue])];
    }
    NSError *error;
    if (![self.dbContext save:&error]) NSLog(@"problem saving to db");
    //NSLog(@"now %@ owes %@ to %@",current.owedBy.name, current.sum, current.owedTo.name);
    
    //if this creat a cycle, eliminate it
    [self eliminateDebtCycelsByDebt:currentDebt];
}

-(void) recomputeDebtWithDrive:(GKManagedDrive *)drive{
    NSSet *hikers=drive.hiker;//##rename this hiker thing?
    //NSLog(@"%d hikers to update", [hikers count]);
    for (GKManagedDriver *hiker in hikers) {
        
        if (!(hiker==drive.driver)) {//no loops!
            //NSLog(@"adding debt by %@ to %@", hiker.name, drive.driver.name);
        [self addDebtBy:hiker to:drive.driver onAmount:drive.length];
       } else NSLog(@"oops, tried to add debt by the driver..");
    }
}


-(GKManagedDriver *)computeSuggestedDriver {
    GKManagedDriver *selectedDriver;
    for (GKManagedDriver *driver in self.participants) {
        //prepare color for later
        driver.color=0;
        
        //see if driver is owed by anyone

        //prepare request
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
        request.predicate=[NSPredicate predicateWithFormat:@"owedTo=%@",driver];
        request.sortDescriptors = NULL;//[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        
        //apply fetch
        NSError *error = nil;
        NSMutableArray *debtsOwed = [[self.dbContext executeFetchRequest:request error:&error] mutableCopy];
        if (debtsOwed == nil) {
            // Handle the error.
            NSLog(@"error in fetch request");
        }
        
        //is our driver not owed by anyone in participants?
        int count=0;
        for (GKManagedDebt *debt in debtsOwed) {
            if ([self.participants containsObject:debt.owedBy]) count++; 
        }
        if (count==0) {
            selectedDriver=driver;
            break;
        }
    }
    if (selectedDriver) return selectedDriver; else {
        NSLog(@"seems there is a debt cycle, please remove cycles!");
        return [self.participants anyObject];
    }
}


-(void) suggestDriver {//computes suggested driver and presents suggestion on tableview
    
    GKManagedDriver *driver=[self computeSuggestedDriver];
    NSString *textForButton;
    if (driver)
        textForButton= [NSString stringWithFormat: 
                                                     @"%@ should drive", driver.name];
    else  textForButton = @"Choose travelers";
        
    self.driveInfoLabel.text =textForButton;
}


#pragma mark - changind states


-(void) makeDesignatedDriverOfCellIndex:(NSIndexPath *)indexPath forParticipants:(NSSet *) participants{
 
    UITableViewCell *driverCell=[self.tableView cellForRowAtIndexPath:indexPath];
    GKManagedDriver *designatedDriver= [self.fetchedResultsController   objectAtIndexPath:indexPath];
    
    if ([participants containsObject:designatedDriver]) { 
    
    for (GKManagedDriver *participant in participants) {
        
        NSLog(@"participant is %@", participant.name);
        UITableViewCell *participantCell= [self.tableView cellForRowAtIndexPath:[self.fetchedResultsController indexPathForObject:participant]];
        NSNumber *sum=[self currentDebtOf:designatedDriver to:participant].sum;
        if (!sum) sum=[NSNumber numberWithFloat:0.00];
        participantCell.detailTextLabel.text=[NSString stringWithFormat:
                                               @"%@ owes me %@ trips",designatedDriver.name, sum];
    }
    driverCell.detailTextLabel.text=@"Designated Driver";
    driverCell.highlighted=YES;

    } else {//attempt to select driver which is not a participant - not supposed to happen
        NSLog(@"attempted making a non participant into driver");
        //driverCell.highlighted=NO;
    }
}

-(void) clearDetailTexts{//reset text and deselect cells
    if (self.driver) {
    NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
    UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
    currentDriverCell.detailTextLabel.text=@"---";//## should zero all cells!!
        currentDriverCell.selected=NO;
        currentDriverCell.highlighted=NO;
    }
    
    for (GKManagedDriver *driver in self.participants) {
        NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:driver];
        UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
        currentDriverCell.detailTextLabel.text=@"---";
        currentDriverCell.selected=NO;
        currentDriverCell.highlighted=NO;
    }
}

- (IBAction)participantsDriverButtonPressed:(UIButton *)sender{
    
    if (self.myState==gkSelectingParticipants){
        if ([self.participants count]>0) {//ok to move to next stage
            
            self.myState=gkSelectingDriver;
            self.driveInfoLabel.text=@"choose driver";
            
            //set initial driver suggestion
            
            self.driver=self.computeSuggestedDriver;
            NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
            [self makeDesignatedDriverOfCellIndex:currentDriverPath forParticipants:self.participants];
            
            //add cancel button
            self.navigationItem.leftBarButtonItem=self.cancelButton;
        } 
    } else if (self.myState==gkSelectingDriver) {
        
        //add trip to database
        
        [self.participants removeObject:self.driver];//participant are now just hikers
        
        self.lastDriveCreated= [GKManagedDrive  
                                newDriveWithDriver:self.driver 
                                hikers:self.participants 
                                date:self.dateForDrive 
                                occured:YES 
                                inContext:self.dbContext];
        
        NSError *error;
        if (![self.dbContext save:&error]) NSLog(@"error saving");
        
        
        //updates debts with new drive
        
        [self recomputeDebtWithDrive:self.lastDriveCreated];
        
        //set internal state
        self.myState=gkDone;
        self.driveInfoLabel.text=@"Done! Trip added...";
        self.navigationItem.leftBarButtonItem=nil;
        
    } else if (self.myState==gkDone) {
        
        [self resetDrive];
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext=NO;
        
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //get details of selected cell
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    GKManagedDriver *driver= [self.fetchedResultsController   objectAtIndexPath:indexPath];
    
    if (self.myState==gkSelectingParticipants) {
        //allow me to change cells without fetcher interference
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext=YES;

        
        //update selection status   
        if ([self.participants containsObject:driver]) {
            [self.participants removeObject:driver];
            cell.selected=NO;
            cell.highlighted=NO;
        } else {
            [self.participants addObject:driver];
            cell.highlighted=YES;
        }
        [self suggestDriver];//compute who should drive and show on button
        
    } else if  (self.myState==gkSelectingDriver) {//my state is gkSelectingDriver
        if ([self.participants containsObject:driver]) {
            if (self.driver) {//get rid of former driver
                NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
                UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
                currentDriverCell.detailTextLabel.text=@"---";
            }
            cell.highlighted=YES;
            self.driver=driver;
            [self makeDesignatedDriverOfCellIndex:indexPath forParticipants:self.participants];
        } else {
                cell.highlighted=NO;
            cell.selected=NO;
        }
    }
    
    //[[tableView cellForRowAtIndexPath:indexPath] setHighlighted:YES];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Driver Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    GKManagedDriver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text =driver.name;
    return cell;
}


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

#pragma mark - date selector delegate

-(void) setDate:(NSDate *)date{
    self.dateForDrive=date;
}



#pragma mark - from photographer table view...

//remember to setupFetchedResultsController
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

-(void)useDocument:(UIManagedDocument *) document {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        // does not exist on disk, so create it
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"finished saving db for creat");
           [self setupFetchedResultsController];
            // [self fetchFlickrDataIntoDocument:self.database];
            
        }];
    } else if (document.documentState == UIDocumentStateClosed) {
        NSLog(@"db exists, will open it");
        // exists on disk, but we need to open it
        [document openWithCompletionHandler:^(BOOL success) {
            
            [self setupFetchedResultsController];
        }];
    } else if (document.documentState == UIDocumentStateNormal) {
        
        // already open and ready to use
        NSLog(@"db already open and ready to use");
        [self setupFetchedResultsController];
    }
}


- (void) resetDrive {
    NSLog(@"resetting drive");
    [self clearDetailTexts];
    self.participants=NULL;//forget participants from previous time..
    self.driveInfoLabel.text=@"Choose Participants and Date";
    //[self.tableView reloadData];//I don't think it's needed
    self.driver=NULL;
    self.dateForDrive=[NSDate date];
    self.myState=gkSelectingParticipants;
    self.navigationItem.leftBarButtonItem=nil;
}

- (void) cancelButtonPressed:(id) sender {
    [self resetDrive];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self resetDrive];//forget participants and data from last time, set date for today, clear table from old text and selection (hopefully)
    
    
    //get global database context   
     [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseReady:) 
                                                 name:@"Database Ready"
                                               object:nil];

    self.dbContext=[GKCarpoolDB sharedContext];
  if ([GKCarpoolDB globalDBIsReady]) 
      [self setupFetchedResultsController];
  else NSLog(@"database not ready, waiting for notification");
}

- (void)  databaseReady:(NSNotification *) notification {
    NSLog(@"got notification that db is ready");
    [self setupFetchedResultsController];
}

#pragma mark - View lifecycle


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
    
    self.debug=NO;NSLog(@" not debug mode");
    
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewDidUnload
{
    [self setDateLabelButton:nil];
    [self setDriveInfoLabel:nil];
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
    [self clearDetailTexts];
    
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

