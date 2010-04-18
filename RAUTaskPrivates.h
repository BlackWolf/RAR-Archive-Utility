/*
 *  RAUTaskPrivates.h
 *  RAR-Archive Utility
 *
 *  Created by BlackWolf on 16.04.10.
 *  Copyright 2010 Mario Schreiner. All rights reserved.
 *
 */

@interface RAUTask ()
@property (readwrite)			int			progress;
@property (readwrite)			TaskResult	result;
@property (readwrite, retain)	NSTask		*task;

-(void)willFinish;
-(void)didFinish;
-(void)taskWillLaunch;
-(void)taskDidLaunch;
-(void)taskDidTerminate:(NSNotification *)notification;
-(void)receivedNewOutput:(NSNotification *)notification;
-(void)parseNewOutput:(NSString *)output;
-(int)parseProgressFromString:(NSString *)output;
@end