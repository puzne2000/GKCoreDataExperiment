//
//  GKCarpoolDB.m
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKCarpoolDB.h"

@implementation GKCarpoolDB


static UIManagedDocument *database ;
static bool databaseIsReady;

+(void) notifyDBReady {
[[NSNotificationCenter defaultCenter] 
 postNotificationName:@"Database Ready" 
 object:nil
 userInfo:nil];
}

+(void)useDocument:(UIManagedDocument *) document {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        // does not exist on disk, so create it
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"finished saving db for creat");
            [GKCarpoolDB notifyDBReady];
            databaseIsReady=YES;
            //[self setupFetchedResultsController];
            // [self fetchFlickrDataIntoDocument:self.database];
            
        }];
    } else if (document.documentState == UIDocumentStateClosed) {
        NSLog(@"db exists, will open it");
        // exists on disk, but we need to open it
        [document openWithCompletionHandler:^(BOOL success) {
            NSLog(@"ljkhljkhljh");
            [GKCarpoolDB notifyDBReady];
            databaseIsReady=YES;
            //[self setupFetchedResultsController];
        }];
    } else if (document.documentState == UIDocumentStateNormal) {
 
        // already open and ready to use
        [GKCarpoolDB notifyDBReady];
        databaseIsReady=YES;

        NSLog(@"db already open and ready to use!!!!!!!!!!!!!!!!!!!!");
        //[self setupFetchedResultsController];
    }
}

+(BOOL) globalDBIsReady {
    return databaseIsReady;
}

+ (void)initialize
{
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //##to work correctly, once initiallized the database should send an nsnotification (in the completion block). ONLY THEN should the core data table view controller prepare the result fetcher (which means that it should listen to notifications)!!!!
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Default Database"];
        NSLog(@"database at %@",url);
        // url is now "<Documents Directory>/Default Database"
        database = [[UIManagedDocument alloc] initWithFileURL:url]; // setter will create this for us on disk
        
        [GKCarpoolDB useDocument:database];
    }
}
+ (NSManagedObjectContext *) sharedContext{
    return database.managedObjectContext;
}

@end
