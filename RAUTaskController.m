//
//  RarController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 10.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Brings together a RAUTask and an RAUTaskViewController and catches the notifications send by them

#import "RAUTaskController.h"
#import "RAURarfile.h"
#import "RAUTaskViewController.h"
#import "RAUTask.h"
#import "RAUExtractTask.h"
#import "Debug.h"


@implementation RAUTaskController
@synthesize viewController, task, taskStartDate, file, password, ETAFirstHalfFactor, ETALastRuntime, ETALastTotalRuntime;

-(id)init {
	if (self = [super init]) {
		self.viewController	=	[[RAUTaskViewController alloc] initWithNibName:@"RarfileView" bundle:[NSBundle mainBundle]];
		ETAFirstHalfFactor = 1.0;
		
		[[NSNotificationCenter defaultCenter] //Listen to when the stop button on the task's view was clicked
		 addObserver:self
		 selector:@selector(stopButtonClicked:)
		 name:TaskViewStopButtonClickedNotification
		 object:self.viewController];
	}
	return self;
}

/* Creates a rarfile, automatically takes care of checking it and asking for a password if necessary */
-(void)createRarfileFromPath:(NSString *)path {
	self.file = [[RAURarfile alloc] initWithFile:path];
	
	[[NSNotificationCenter defaultCenter] //Listen to when the infos about the rarfile are completly gathered
	 addObserver:self
	 selector:@selector(fileWasCompleted:)
	 name:RarfileCompletedNotification
	 object:self.file];
}

/* Automatically called if the initial infos about self.file were gathered */
-(void)fileWasCompleted:(NSNotification *)notification {
	if (self.file.isValid == NO) { 
		[self didFinish];
	} else {
		if (self.file.isPasswordProtected == YES) { //We need a password sheet - send a notification to make the appDelegate show it
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskControllerNeedsPasswordNotification object:self];
		} else { //Normal rarfile
			[self launchTask];
		}
	}
}

/* Tells the Controller to try a password on the rarfile */
-(void)checkPassword:(NSString *)passwordToCheck {
	if ([passwordToCheck length] == 0) passwordToCheck = nil;
	RAUExtractTask *checkPassword = [[RAUExtractTask alloc] initWithFile:self.file mode:ExtractTaskModeCheck password:passwordToCheck];
	
	[checkPassword launchTask];
	
	[[NSNotificationCenter defaultCenter] //Listen to when the pwd check finishes
	 addObserver:self
	 selector:@selector(passwordHasBeenChecked:)
	 name:TaskDidFinishNotification
	 object:checkPassword];
}

/* Automatically called when a password provided in checkPassword: was checked. We now need to see if the password is valid */
-(void)passwordHasBeenChecked:(NSNotification *)notification {
	RAUExtractTask *checkPassword = (RAUExtractTask *)[notification object];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskDidFinishNotification object:checkPassword];
	
	if (checkPassword.result == TaskResultPasswordInvalid)
		[[NSNotificationCenter defaultCenter] postNotificationName:TaskControllerNeedsPasswordNotification object:self];
	else {
		self.password = checkPassword.password;
		[self launchTask];
	}
	
	[checkPassword release];
}

/* Called before the task controlled by this class is launched. Can be overwritten by subclasses to implement own tasks */
-(void)taskWillLaunch {
	self.task = [[RAUTask alloc] init];
}

/* Launches a task and sets up NSNotification observers */
-(void)launchTask {
	self.taskStartDate = [[NSDate alloc] init];
	
	[self taskWillLaunch];
	
	[[NSNotificationCenter defaultCenter] //Listen to when the task finishes
	 addObserver:self
	 selector:@selector(taskDidFinish:)
	 name:TaskDidFinishNotification
	 object:self.task];
	[[NSNotificationCenter defaultCenter] //Listen to when the progress of the task is updated
	 addObserver:self
	 selector:@selector(progressWasUpdated:)
	 name:TaskHasUpdatedProgressNotification
	 object:self.task];
	
	[self.task launchTask];
	
	[self taskDidLaunch];
	
	[[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] 
								 forMode:NSDefaultRunLoopMode];
}
-(void)taskDidLaunch {
}

-(void)progressTimerFired:(NSTimer*)theTimer {
	[self progressWasUpdated:nil];
	if (self.task.task.isRunning == NO) [theTimer invalidate];
}

/* Automatically invoked when the task updates it's progress. Updates the taskView */
-(void)progressWasUpdated:(NSNotification *)notification {
	[self.viewController.progress setDoubleValue:(double)self.task.progress];
	
	if (self.task.progress == 100) {
		[self.viewController.statusLabel	setStringValue:NSLocalizedString(@"Finishing…", nil)];
		[self.viewController.progress		setIndeterminate:YES];
		[self.viewController.progress		startAnimation:self];
		[self.viewController.partsLabel		setHidden:YES];
	}
}

/* Automatically invoked when the X-Button was clicked - user wants to cancel the task */
-(void)stopButtonClicked:(NSNotification *)notification {
	[self terminateTask];
}
/* Called when we want to manually terminate the current task */
-(void)terminateTask {
	//Set GUI to "Cancelling" status
	[self.viewController.statusLabel	setStringValue:NSLocalizedString(@"Cancelling…", nil)];
	[self.viewController.progress		setIndeterminate:YES];
	[self.viewController.progress		startAnimation:self];
	
	if (self.task != nil) {
		if (self.task.task.isRunning == YES) [self.task terminateTask];
		else								 [self taskDidFinish:nil];
	}
	else 
		[self taskDidFinish:nil];
}

/* Automatically called when self.task did finish */
-(void)taskDidFinish:(NSNotification *)notification {
	[self didFinish]; //Extraction finished means Controller is not needed anymore (it's only purpose is to control the task)
}

/* Called when the controller finished its job */
-(void)didFinish {
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskControllerDidFinishNotification object:self];
}

-(NSString *)getETAString {	
	double runtime = [[NSDate date] timeIntervalSinceDate:self.taskStartDate];
	if ((runtime < 25 && self.task.progress <= 2) || self.task.progress == 0) return NSLocalizedString(@"Calculating…", nil);
	
	double totalRuntime;
	if (ETALastRuntime == 0) {
		totalRuntime = runtime*(100.0/self.task.progress);
		totalRuntime *= ETAFirstHalfFactor; //At the beginning, estimates are always too low. We rather want too high estimates
		
		ETALastRuntime = runtime;
		ETALastTotalRuntime = totalRuntime;
	} else {
		double weighting = 0.4*((runtime-ETALastRuntime)/10);
		if (weighting > 1) weighting = 1;
		
		double currentETA = runtime*(100.0/self.task.progress);
		if (self.task.progress <= 50) currentETA *= 1 + (1-self.task.progress/50.0)*(ETAFirstHalfFactor-1);
		totalRuntime = weighting*currentETA + (1-weighting)*ETALastTotalRuntime;
		
		if ((runtime-ETALastRuntime) >= 10) {
			ETALastRuntime = runtime;
			ETALastTotalRuntime = totalRuntime;
		}
	}
	
	double remainingRuntime = totalRuntime-runtime;
	if (remainingRuntime < 10) return NSLocalizedString(@"A few seconds", nil);
	if (remainingRuntime < 60) return NSLocalizedString(@"Less than a minute", nil);
	if (remainingRuntime < 90) return NSLocalizedString(@"About a minute", nil);
	if (remainingRuntime < 60*60) return [NSString stringWithFormat:NSLocalizedString(@"About %d minutes", nil), (int)round(remainingRuntime/60)];
	if (remainingRuntime < 90*60) return NSLocalizedString(@"About an hour", nil); 
	if (remainingRuntime < 24*60*60) return [NSString stringWithFormat:NSLocalizedString(@"About %d hours", nil), (int)round(remainingRuntime/60/60)];
	if (remainingRuntime < 36*60*60) return NSLocalizedString(@"About a day", nil);
	return [NSString stringWithFormat:NSLocalizedString(@"About %d days", nil), (int)round(remainingRuntime/24/60/60)];
}

-(void)dealloc {
	/*[[NSNotificationCenter defaultCenter] removeObserver:self name:RarfileCompletedNotification object:self.file];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskViewStopButtonClickedNotification object:self.viewController];
	if (self.task != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskDidFinishNotification object:self.task];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskHasUpdatedProgressNotification object:self.task];
	}*/
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[viewController	release];
	[task			release]; 
	
	[super dealloc];
}

@end
