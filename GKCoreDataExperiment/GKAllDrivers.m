//
//  GKAllDrivers.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 3/30/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKAllDrivers.h"
#import "GKManagedDriver.h"
#import "GKSetDriverName.h"
#import "GKCarpoolDB.h"

@implementation GKAllDrivers

#pragma mark - from photographer table view...

@synthesize dbContext=_dbContext;




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



-(void) createDriverWithName:(NSString *) name{
// Create and configure a new instance of the Event entity.
GKManagedDriver *driver = (GKManagedDriver *)[NSEntityDescription insertNewObjectForEntityForName:@"Driver" inManagedObjectContext:self.dbContext];
    driver.name=name;
    NSError *error = nil;
    if (![self.dbContext save:&error]) {
        NSLog(@"some error");
    }
}



// Override to support editing the table view.
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
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        [self createDriverWithName:@"New Driver"];
        // Commit the change.
        NSError *error = nil;
        if (![self.dbContext save:&error]) {
            NSLog(@"some error");
        }

    }   
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //self.navigationController.toolbarHidden=NO;
    //get global database context   
    self.dbContext=[GKCarpoolDB sharedContext];
    NSLog(@"got context :%@", self.dbContext);
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
    
    
    if ([segue.identifier isEqualToString:@"SetDriverName"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        GKManagedDriver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        GKSetDriverName *destination=segue.destinationViewController;
        destination.driver=driver;
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



- (IBAction)addDriverItem:(UIBarButtonItem *)sender{
    [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:NULL];
}

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


@end
