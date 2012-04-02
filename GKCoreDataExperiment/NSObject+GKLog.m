//
//  NSObject+GKLog.m
//  Touchy
//
//  Created by Guy (me) on 3/16/12.
//  Copyright (c) 2012 The Hebrew University. All rights reserved.
//

#import "NSObject+GKLog.h"

@implementation NSObject (GKLog)

-(void) GKLog:(NSString *)message{
#ifdef DEBUG_MODE
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:message 
     object:self
     userInfo:nil];
#endif
}


@end
