//
//  GKLogger.m
//  Touchy
//
//  Created by Guy (me) on 3/16/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "GKLogger.h"
#import "GKDataViewController.h"
#import "GKRootViewController.h"
#import "GKFileListTVC.h"
#import "GKNotebookFileHandler.h"
#import "GKPlayer.h"
#import "GKPage.h"
#import "GKRecorder.h"

@implementation GKLogger{
    NSMutableSet *_logFrom;
}

static GKLogger *sharedLogger;

-(void) receiveNotification:(NSNotification *) notification{
    NSString *class=NSStringFromClass([notification.object class]);
    if ([_logFrom containsObject:class]){
        NSLog(@"%@:  %@",[notification.object class], notification.name);

        //for possible future use:
        //NSLog(@"userinfo:%@", notification.userInfo);
    } 
}

+(void) initialize{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedLogger=[[GKLogger alloc] init];
    }
}

-(GKLogger *) init{
    self=[super init];
    if (!self) return nil;
    _logFrom=[NSMutableSet set];

    /////////////////////////////////////////////////////////
    //update who I want to listen to
    ///////////////////////////////////////////////////////////
    
    //[_logFrom addObject:NSStringFromClass([GKDataViewController class])];
    [_logFrom addObject:NSStringFromClass([GKRootViewController class])];
    //[_logFrom addObject:NSStringFromClass([GKWritePad class])];
    //[_logFrom addObject:NSStringFromClass([GKSquiggle class])];
    //[_logFrom addObject:NSStringFromClass([GKFileListTVC class])];
    [_logFrom addObject:NSStringFromClass([GKModelController class])];
    [_logFrom addObject:NSStringFromClass([GKNotebookFileHandler class])];
    [_logFrom addObject:NSStringFromClass([GKPlayer class])];
    [_logFrom addObject:NSStringFromClass([GKRecorder class])];
//    [_logFrom addObject:NSStringFromClass([GKPage class])];
   // [_logFrom addObject:NSStringFromClass([GKNotebook class])];
    
    
    //listen to notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:) 
                                                 name:nil
                                               object:nil];
    NSLog(@"logger initialized");
    return self;
}

- (void) prepareToDie{
    NSLog(@"logger is preparing to die");
     [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
