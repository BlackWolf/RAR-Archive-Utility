/*
 *  RAUTaskControllerPrivates.h
 *  RAR-Archive Utility
 *
 *  Created by BlackWolf on 17.04.10.
 *  Copyright 2010 Mario Schreiner. All rights reserved.
 *
 */

@interface RAUTaskController ()
@property (readwrite, retain)	RAURarfile				*rarfile;
@property (readwrite, retain)	RAUTask					*task;
@property (readwrite, retain)	NSDate					*taskStartDate;
@property (readwrite, retain)	RAUTaskViewController	*viewController;
@property (readwrite)			double					ETAFirstHalfFactor;
@property (readwrite)			double					ETALastRuntime;
@property (readwrite)			double					ETALastTotalRuntime;

-(void)initView;
-(void)didFinish;
-(void)rarfileWasChecked:(NSNotification *)notification;
-(void)passwordWasChecked:(NSNotification *)notification;
-(void)taskWillLaunch;
-(void)taskDidLaunch;
-(NSString *)getETAString;
@end