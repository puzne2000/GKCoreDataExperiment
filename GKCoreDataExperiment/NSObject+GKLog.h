//
//  NSObject+GKLog.h
//  Touchy
//
//  Created by Guy (me) on 3/16/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import <Foundation/Foundation.h>
#define DEBUG_MODE @"YES"

@interface NSObject (GKLog)

-(void) GKLog:(NSString *)message;

@end
