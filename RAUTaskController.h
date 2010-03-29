//
//  RarController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 10.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define TaskControllerNeedsPasswordNotification	@"TaskControllerNeedsPasswordNotification"
#define TaskControllerDidFinishNotification		@"TaskControllerDidFinishNotification"


@class RAUTaskViewController, RAUTask, RAURarfile;
@interface RAUTaskController : NSObject {
	RAURarfile				*file;
	NSString				*password;
	RAUTask					*task;
	NSDate					*taskStartDate;
	RAUTaskViewController	*viewController;
	double					ETAFirstHalfFactor;
	double					ETALastRuntime;
	double					ETALastTotalRuntime;
}

@property (readwrite, assign)	RAURarfile				*file;
@property (readwrite, copy)		NSString				*password;
@property (readwrite, assign)	RAUTask					*task;
@property (readwrite, assign)	NSDate					*taskStartDate;
@property (readwrite, assign)	RAUTaskViewController	*viewController;
@property (assign)				double					ETAFirstHalfFactor;
@property (assign)				double					ETALastRuntime;
@property (assign)				double					ETALastTotalRuntime;

-(void)createRarfileFromPath:(NSString *)path;
-(void)fileWasCompleted:(NSNotification *)notification;
-(void)checkPassword:(NSString *)passwordToCheck;
-(void)passwordHasBeenChecked:(NSNotification *)notification;
-(void)taskWillLaunch;
-(void)launchTask;
-(void)taskDidLaunch;
-(void)terminateTask;
-(void)taskDidFinish:(NSNotification *)notification;
-(void)progressWasUpdated:(NSNotification *)notification;
-(void)stopButtonClicked:(NSNotification *)notification;
-(void)didFinish;
-(NSString *)getETAString;

@end
