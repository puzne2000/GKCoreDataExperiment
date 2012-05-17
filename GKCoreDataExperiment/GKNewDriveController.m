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



#pragma mark - helper methods

-(void) saveContext {
    NSError *error;
    if (![self.dbContext save:&error]) {
        NSLog(@"error saving: %@", error.localizedDescription);
    }
}

#pragma mark - fetch requests
-(NSArray *)resultForRequest:(NSFetchRequest *)request{
    NSError *error = nil;
    NSArray *result = [self.dbContext executeFetchRequest:request error:&error];
    if (result == nil) {
        // Handle the error.
        NSLog(@"error in fetch request");
    }
    return result;
}


- (NSArray *) debtsOwedTo:(GKManagedDriver *)driver{
    //prepare request
    static NSFetchRequest *request;
    if (!request) request= [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
    request.predicate=[NSPredicate predicateWithFormat:@"owedTo=%@",driver];
    request.sortDescriptors = NULL;
    
    //apply fetch
    return [self resultForRequest:request];
}

- (NSArray *) debtsOwedBy:(GKManagedDriver *)driver{
    //prepare request
    static NSFetchRequest *request;
    if (!request) request= [NSFetchRequest fetchRequestWithEntityName:@"Debt"];
    request.predicate=[NSPredicate predicateWithFormat:@"owedBy=%@",driver];
    request.sortDescriptors = NULL;
    
    //apply fetch
    return [self resultForRequest:request];
}

#pragma mark - debt and driver suggestions


-(GKManagedDriver *)computeSuggestedDriver {
    GKManagedDriver *selectedDriver;
    NSMutableSet *possibleDrivers=[NSMutableSet set];
    int maxOwed=0;//=0
    
    
    //find drivers owed by noone
    for (GKManagedDriver *driver in self.participants) {
        //prepare color for later
        driver.color=0;//##don't think this is needed
        
        //see if driver is owed by anyone

        NSArray *debtsOwed =[self debtsOwedTo:driver];
        //is our driver not owed by anyone in participants?
        int count=0;
        for (GKManagedDebt *debt in debtsOwed) {
            if ([self.participants containsObject:debt.owedBy]) count++; 
        }
        if (count==0) {
            [possibleDrivers addObject:driver];
        }
    }
    
    //from those, find those that owe the maximum
    for (GKManagedDriver *driver in possibleDrivers) {
        
        NSArray *debtsOwedByDriver=[self debtsOwedBy:driver] ;
        int count=0;
        for (GKManagedDebt *debt in debtsOwedByDriver) {
            if ([self.participants containsObject:debt.owedTo]) count++ ;
        }
        
        NSLog(@"%@ owes %d people", driver.name, count );

        if  (count>=maxOwed){
            selectedDriver=driver;
            maxOwed=count;
        }
        
    }
    if (selectedDriver) return selectedDriver; else {
        if ([self.participants count]>0) NSLog(@"seems there is a debt cycle, please remove cycles!");
        return [self.participants anyObject];
    }
}

/*
-(void) suggestDriver {//computes suggested driver and presents suggestion on tableview
    
    GKManagedDriver *driver=[self computeSuggestedDriver];
    NSString *textForButton;
    if (driver)
        textForButton= [NSString stringWithFormat: 
                                                     @"%@ should drive", driver.name];
    else  textForButton = @"Choose travelers";
        
    self.driveInfoLabel.text =textForButton;
}
*/

#pragma mark - changind states


-(void) makeDesignatedDriverOfCellIndex:(NSIndexPath *)indexPath forParticipants:(NSSet *) participants{
    
    UITableViewCell *driverCell=[self.tableView cellForRowAtIndexPath:indexPath];
    GKManagedDriver *designatedDriver= [self.fetchedResultsController   objectAtIndexPath:indexPath];
    
    if ([participants containsObject:designatedDriver]) { 
        
        for (GKManagedDriver *participant in participants) {
            
            NSLog(@"participant is %@", participant.name);
            UITableViewCell *participantCell= [self.tableView cellForRowAtIndexPath:[self.fetchedResultsController indexPathForObject:participant]];
            participantCell.selectionStyle=UITableViewCellSelectionStyleGray;
            NSNumber *sum=[designatedDriver currentDebtTo:participant].sum;
            if (sum) {
                //participantCell.detailTextLabel.textColor=[UIColor greenColor];
                participantCell.detailTextLabel.text=[NSString stringWithFormat:
                                                      @"%@ owes me %@ drives",designatedDriver.name, sum];     
            } else {
                sum=[participant currentDebtTo:designatedDriver].sum;
                if (sum) {
                    //participantCell.detailTextLabel.textColor=[UIColor magentaColor];
                    participantCell.detailTextLabel.text=[NSString stringWithFormat:
                                                          @"I owe %@  %@ drives",designatedDriver.name, sum];     
                } else {
                    participantCell.detailTextLabel.text=@"---";
                }
            }
            
        }
        driverCell.detailTextLabel.text=@"Designated Driver";
        driverCell.selectionStyle=UITableViewCellSelectionStyleBlue;
        driverCell.highlighted=YES;
        
    } else {//attempt to select driver which is not a participant - not supposed to happen
        NSLog(@"attempted making a non participant into driver");
        //driverCell.highlighted=NO;
    }
}

-(void) resetParticipantAndDriverCells{//reset text and deselect cells
    NSMutableSet *cellsToReset;
    if (self.participants)
        cellsToReset=[NSMutableSet setWithSet:self.participants];
    else cellsToReset=[NSMutableSet set];
    if (self.driver)
        [cellsToReset addObject:self.driver];
 
    for (GKManagedDriver *driver in cellsToReset) {
        NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:driver];
        UITableViewCell *currentDriverCell= [self.tableView cellForRowAtIndexPath:currentDriverPath];
        currentDriverCell.selectionStyle=UITableViewCellSelectionStyleBlue;
        currentDriverCell.detailTextLabel.text=@"---";
        currentDriverCell.selected=NO;
        currentDriverCell.highlighted=NO;
    }
}

- (IBAction)participantsDriverButtonPressed:(UIButton *)sender{
    
    if (self.myState==gkSelectingParticipants){
        if ([self.participants count]>0) {//ok to move to next stage
            
            self.myState=gkSelectingDriver;
            GKManagedDriver *suggestedDriver=[self computeSuggestedDriver];
            self.driveInfoLabel.text=[NSString stringWithFormat:@"choose driver (%@ perhaps?)", suggestedDriver.name];
            
            //set initial driver suggestion
            
            self.driver=suggestedDriver;
            NSIndexPath *currentDriverPath=[self.fetchedResultsController indexPathForObject:self.driver];
            [self makeDesignatedDriverOfCellIndex:currentDriverPath forParticipants:self.participants];
            
            //add cancel button
            self.navigationItem.leftBarButtonItem=self.cancelButton;
        } 
    } else if (self.myState==gkSelectingDriver) {
        
        //add drive to database
        
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
        [self.lastDriveCreated addAssociatedDebtsToRecord];
        
        //set internal state
        self.myState=gkDone;
        self.driveInfoLabel.text=@"Done! Have a nice Drive!";
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
        //[self suggestDriver];//compute who should drive and show on button
        
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
}

#pragma mark - Table view data source


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
       }
 }






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
}





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
    [self resetParticipantAndDriverCells];
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
    [self resetParticipantAndDriverCells];
    [self saveContext];
    
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

