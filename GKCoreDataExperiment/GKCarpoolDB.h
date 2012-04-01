//
//  GKCarpoolDB.h
//  GKCoreDataExperiment
//
//  Created by Guy (me) on 4/1/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GKCarpoolDB : NSObject

+ (NSManagedObjectContext *) sharedContext;

@end
