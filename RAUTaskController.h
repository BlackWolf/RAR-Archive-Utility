//
//  RAUTaskController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h" //Importing RAUTaskDelegate


@class RAUTaskController;
@protocol RAUTaskControllerDelegate
-(void)taskControllerNeedsPassword:(RAUTaskController *)needyController;
-(void)taskControllerRarfileInvalid:(RAUTaskController *)invalidController;
-(void)taskControllerIsReady:(RAUTaskController *)readyController;
-(void)taskControllerDidFinish:(RAUTaskController *)finishedController;
@end


@class RAUPath, RAURarfile, RAUTask, RAUTaskViewController;
@interface RAUTaskController : NSObject <RAUTaskDelegate> {
	id<RAUTaskControllerDelegate>	delegate;
	RAUPath							*rarfilePath;
	RAURarfile						*rarfile;
	NSString						*passwordArgument;
	RAUTask							*task;
	NSDate							*taskStartDate;
	RAUTaskViewController			*viewController;
	double							ETAFirstHalfFactor;
	double							ETALastRuntime;
	double							ETALastTotalRuntime;
}

@property (readwrite, assign)	id<RAUTaskControllerDelegate>	delegate;
@property (readwrite, copy)		RAUPath							*rarfilePath;
@property (readonly, assign)	RAURarfile						*rarfile;
@property (readwrite, copy)		NSString						*passwordArgument;
@property (readonly, assign)	RAUTask							*task;
@property (readonly, assign)	NSDate							*taskStartDate;
@property (readonly, assign)	RAUTaskViewController			*viewController;
@property (readonly)			double							ETAFirstHalfFactor;
@property (readonly)			double							ETALastRuntime;
@property (readonly)			double							ETALastTotalRuntime;

-(void)initView;
-(void)didFinish;
-(void)rarfileWasChecked:(NSNotification *)notification;
-(void)passwordWasChecked:(NSNotification *)notification;
-(void)taskWillLaunch;
-(void)launchTask;
-(void)taskDidLaunch;
-(void)terminateTask;
-(void)taskDidFinish:(RAUTask *)finishedTask;
-(void)progressTimerFired:(NSTimer*)theTimer;
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask;
-(void)stopButtonClicked:(NSNotification *)notification;
-(NSString *)getETAString;

@end
