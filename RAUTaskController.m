//
//  RarController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 10.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Superclass for all TaskControllers. Gets the common methods in a central place.
// In general, TaskController manage an RAUTask, catch notifications from it or get send messages from it
// Also, the TaskController brings together the RAUTask and the RAUTaskView that goes with it
//

#import "RAUTaskController.h"
#import "RAURarfile.h"
#import "RAUTaskViewController.h"
#import "RAUTask.h"
#import "RAUExtractTask.h"


#warning I think this class and the subclasses need to be rewritten greatly. they seem to miss a lot of logic (what belongs where etc.)
@implementation RAUTaskController

#pragma mark -

-(id)init {
	if (self = [super init]) {
		self.viewController	= [[RAUTaskViewController alloc] initWithNibName:@"RarfileView" bundle:[NSBundle mainBundle]];
		ETAFirstHalfFactor	= 1.0;
		
		 //Listen to when the stop button on the task's view was clicked
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(stopButtonClicked:)
													 name:TaskViewStopButtonClickedNotification
												   object:self.viewController];
	}
	return self;
}

-(void)didFinish {
#warning again, it would probably make more sense to use a delegate method (not sure this time)
	//This controller is done, send a notification about this
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskControllerDidFinishNotification object:self];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[file			release]; 
	[password		release];
	[task			release]; 
	[taskStartDate	release];
	[viewController	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Rarfile
@synthesize file, password;

#warning rewrite this to "setFile:". Also, think about if it really makes sense in the superclass
/* Creates an RAURarfile from a given path and takes care of making sure it's valid */
-(void)createRarfileFromPath:(NSString *)path {
	self.file = [[RAURarfile alloc] initWithFile:path];
	
	//Listen to when the infos about the rarfile are completly gathered
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(fileWasCompleted:)
												 name:RarfileCompletedNotification
											   object:self.file];
}

/* Automatically called when all infos about self.file were gathered */
-(void)fileWasCompleted:(NSNotification *)notification {
	if (self.file.isValid == NO) { 
		[self didFinish];
	} else {
		if (self.file.isPasswordProtected == YES) { //We need a password sheet - send a notification to make the appDelegate show it
#warning maybe a delegate method would be more suitable here?
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskControllerNeedsPasswordNotification object:self];
		} else { //Normal rarfile
			[self launchTask];
		}
	}
}

/* Try a password on the rarfile in self.file */
-(void)checkPassword:(NSString *)passwordToCheck {
	if ([passwordToCheck length] == 0) passwordToCheck = nil;
	RAUExtractTask *checkPassword = [[RAUExtractTask alloc] initWithFile:self.file mode:ExtractTaskModeCheck password:passwordToCheck];
	
	[checkPassword launchTask];
	
	//Listen to when the pwd check finishes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(passwordHasBeenChecked:)
												 name:TaskDidFinishNotification
											   object:checkPassword];
}

/* Automatically called after a password has been tried on self.file */
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

#pragma mark -
#pragma mark The RAUTask
@synthesize task, taskStartDate;

-(void)taskWillLaunch {
	//We assign a generic RAUTask here. It would be wise for subclasses to overwrite this with a subclass of RAUTask
	self.task = [[RAUTask alloc] init];
}

-(void)launchTask {
	self.taskStartDate = [[NSDate alloc] init]; 
	
	[self taskWillLaunch];
	
	//Listen to when the task finishes and for updated progress
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDidFinish:)
												 name:TaskDidFinishNotification
											   object:self.task];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(progressWasUpdated:)
												 name:TaskHasUpdatedProgressNotification
											   object:self.task];
	
	[self.task launchTask];
	
	[self taskDidLaunch];
	
	//We set a timer here, so the ETA is updated at least every 10 seconds
	[[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] 
								 forMode:NSDefaultRunLoopMode];
}
-(void)taskDidLaunch {}

-(void)terminateTask {
	//Set GUI to "Cancelling" status
	[self.viewController.statusLabel	setStringValue:NSLocalizedString(@"Cancelling…", nil)];
	[self.viewController.progress		setIndeterminate:YES];
	[self.viewController.progress		startAnimation:self];
	
	//If the task is running, terminate it (which will trigger taskDidFinish:), otherwise just call taskDidFinish:
	if (self.task != nil) {
		if (self.task.task.isRunning == YES) [self.task terminateTask];
		else								 [self taskDidFinish:nil];
	}
	else 
		[self taskDidFinish:nil];
}

/* Automatically called when the RAUTask did finish */
-(void)taskDidFinish:(NSNotification *)notification {
	[self didFinish]; //Task finished means Controller is not needed anymore (it's only purpose is to control the task)
}

#pragma mark -
#pragma mark TaskView (UI)
@synthesize viewController;

/* Automatically called every 10 seconds to update the progress UI */
-(void)progressTimerFired:(NSTimer*)theTimer {
	[self progressWasUpdated:nil];
	if (self.task.task.isRunning == NO) [theTimer invalidate];
}

/* Automatically invoked when the task updates it's progress */
-(void)progressWasUpdated:(NSNotification *)notification {
	[self.viewController.progress setDoubleValue:(double)self.task.progress];
	
	//We finished, set UI to "Finish" while the task finishes
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

#pragma mark -
#pragma mark Utility methods
@synthesize ETAFirstHalfFactor, ETALastRuntime, ETALastTotalRuntime;

/* Uses self.taskStartDate and the current progress to calculate the ETA based on EWMA */
-(NSString *)getETAString {	
	double runtime = [[NSDate date] timeIntervalSinceDate:self.taskStartDate];
	
	//If progress <= 2 just show "Calculating…", but show an ETA after a max of 25 seconds 
	if ((runtime < 25 && self.task.progress <= 2) || self.task.progress == 0) return NSLocalizedString(@"Calculating…", nil);
	
	double totalRuntime;
	if (ETALastRuntime == 0) { //This method was never run before
		/* Make a first assumption. ETA is always too low at the beginning, so we multiply it with FirstHalfFactor (which can be 
		 overwritten by subclasses) */
		totalRuntime = runtime*(100.0/self.task.progress); 
		totalRuntime *= ETAFirstHalfFactor; 
		
		ETALastRuntime = runtime;
		ETALastTotalRuntime = totalRuntime;
	} else { 
		/* Here we use EWMA, which takes old ETAs in account but still makes the current data point very significant. The formula:
		 x*Y(t) + (1-x)*S(t-1), where ...
		 x is a factor between 0 and 1. bigger x means that old ETA-measurements get meaningless faster
		 Y(t) is the current ETA (calculated by the same basic formula used above)
		 S(t-1) is the EWMA-based ETA that calculated the last time
		 
		 Two additions are made to this formula:
		 1) x is dynamic. Since this method should calculate an ETA every 10 seconds, but isn't always called after exactly 10 seconds,
			we calculate a weighting based on the actual time since the last ETA was calculated
		 2) Like explained above, the ETA gets calculated way too low at the beginning, which is why we multiply it by an addition factor
			as long as progress <= 50%. This factor decreases when the progress increases. With progress=0 the factor is FirstHalfFactor,
			which progress=25 it's FirstHalfFactor/2 and with progress>50 it's always 1
		 
		 Yeah, sick, I know ... ;-) I don't expect anyone to actually get this
		*/
		 
		double weighting = 0.4*((runtime-ETALastRuntime)/10);
		if (weighting > 1) weighting = 1; //x must be between 0 and 1
		
		double currentETA = runtime*(100.0/self.task.progress); //ETA calculated by basic formula
		
		//On the first half of the progress, boost the ETA based on ETAFirstHalfFactor (which decreases over time)
		if (self.task.progress <= 50) currentETA *= 1 + (1-self.task.progress/50.0)*(ETAFirstHalfFactor-1);
		totalRuntime = weighting*currentETA + (1-weighting)*ETALastTotalRuntime; //Actual EWMA formula
		
		/* If the last calculation is younger, we simply display the current calculations, but they don't get taken into account in the next
		 EWMA calculation (EWMA data points need to be evenly spread) */
		if ((runtime-ETALastRuntime) >= 10) {
			ETALastRuntime = runtime;
			ETALastTotalRuntime = totalRuntime;
		}
	}
	
	//Finally an easy part: Take the ETA and transform it into a human-readable string
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

@end
