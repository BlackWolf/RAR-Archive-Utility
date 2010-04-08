//
//  RAUTaskController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This class should be instantiated if you need access to an RAUTask (a checkTask is the exception). It creates the task and also a
// taskView and always keeps the view up-to-date with the latest progress from the task. It's also responsible for checking a rarfile or
// password before passing it to the task, but generally all arguments set to the controller are passed on to the task without modification.
// If something happens, it sends messages to its delegate to inform it. Like RAUTask, this superclass brings together common methods to all 
// TaskController but should not be created directly, only subclasses of it
//

#import "RAUTaskController.h"
#import "RAURarfile.h"
#import "RAUCheckTask.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"
#import "RAUTaskViewController.h"


@implementation RAUTaskController

#pragma mark -
@synthesize delegate;

-(id)init {
	if (self = [super init]) {
		viewController		= [[RAUTaskViewController alloc] initWithNibName:@"RarfileView" bundle:[NSBundle mainBundle]];
		ETAFirstHalfFactor	= 1.0; //Standard value, can be overwritten by subclasses
		
		[self performSelector:@selector(initView) withObject:nil afterDelay:0];
		
		//Listen to when the stop button on the task's view was clicked
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(stopButtonClicked:)
													 name:TaskViewStopButtonClickedNotification
												   object:viewController];
	}
	return self;
}

-(void)initView {
	//Set the view to "Preparing" state 
	[viewController.statusLabel	setStringValue:NSLocalizedString(@"Preparing…", nil)];
	[viewController.progress	setIndeterminate:YES];
	[viewController.progress	startAnimation:self];
	[viewController.partsLabel	setHidden:YES];
}

-(void)didFinish {
	[delegate taskControllerDidFinish:self];
}

-(void)dealloc {
	[rarfilePath		release];
	[rarfile			release]; //alloced in setRarfilePath
	[passwordArgument	release];
	[task				release]; //alloced in taskWillLaunch
	[taskStartDate		release]; //alloced in launchTask
	[viewController		release]; //alloced in init
	
	[super dealloc];
}

#pragma mark -
#pragma mark Rarfile & Password
@synthesize rarfilePath, rarfile, passwordArgument;

-(void)setRarfilePath:(RAUPath *)value {
	[rarfilePath release];
	rarfilePath = [value copy];
	
	// When the rarfilePath is set, the rarfile is automatically set and checked. When the check is done, a message is sent to the delegate
	[rarfile release];
	rarfile = [[RAURarfile alloc] initWithFilePath:self.rarfilePath];
	
	//Listen to when the infos about the rarfile are completly gathered and to when a password-check finished
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(rarfileWasChecked:)
												 name:RarfileWasCheckedNotification
											   object:rarfile];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(passwordWasChecked:)
												 name:RarfilePasswordWasCheckedNotification
											   object:rarfile];
}

/* Automatically called when all infos about rarfile were gathered */
-(void)rarfileWasChecked:(NSNotification *)notification {
	if (rarfile.isValid == NO) { 
		[delegate taskControllerRarfileInvalid:self];
	} else {
		if (rarfile.isPasswordProtected == YES) { 
			[delegate taskControllerNeedsPassword:self];
		} else { //Normal rarfile
			[delegate taskControllerIsReady:self];
		}
	}
}

-(void)setPasswordArgument:(NSString *)value {
	if ([value length] > 0 && rarfile.passwordFound == NO) {
		[passwordArgument release];
		passwordArgument = [value copy];
		
		[rarfile checkPassword:value];
		//We already set up a listener to RarfilePasswordWasCheckedNotification in setRarfilePath:
	}
}

-(void)passwordWasChecked:(NSNotification *)notification {
	if (rarfile.passwordFound == YES) {
		passwordArgument = [self.rarfile.correctPassword copy];
		[delegate taskControllerIsReady:self];
	} else {
		[delegate taskControllerNeedsPassword:self];
	}
}

#pragma mark -
#pragma mark The RAUTask
@synthesize task, taskStartDate;

-(void)taskWillLaunch {
	//We assign a generic RAUTask here. It would be wise for subclasses to overwrite this with a subclass of RAUTask
	[task release];
	task = [[RAUTask alloc] init];
}

-(void)launchTask {
	[taskStartDate release];
	taskStartDate = [[NSDate alloc] init]; 
	
	[self taskWillLaunch];
	
	[task setDelegate:self];
	[task launchTask];
	
	[self taskDidLaunch];
	
	//We set a timer here, so the ETA is updated at least every 10 seconds
	[[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] 
								 forMode:NSDefaultRunLoopMode];
}
-(void)taskDidLaunch {}

-(void)terminateTask {
	//Set GUI to "Cancelling" status
	[viewController.statusLabel	setStringValue:NSLocalizedString(@"Cancelling…", nil)];
	[viewController.progress	setIndeterminate:YES];
	[viewController.progress	startAnimation:self];
	[viewController.partsLabel	setHidden:YES];
	[viewController lockView];
	
	//If the task is running, terminate it (which will trigger taskDidFinish:), otherwise just call taskDidFinish:
	if (task != nil) {
		[task terminateTask];
	}
	else 
		[self taskDidFinish:nil];
}

/* Automatically called when the RAUTask did finish */
-(void)taskDidFinish:(RAUTask *)finishedTask {
	if (finishedTask == task)
		[self didFinish]; 
}

#pragma mark -
#pragma mark TaskView (UI)
@synthesize viewController;

/* Automatically called every 10 seconds to update the progress UI */
-(void)progressTimerFired:(NSTimer*)theTimer {
	[self taskProgressWasUpdated:task];
	if (task.task.isRunning == NO) [theTimer invalidate];
}

/* Automatically invoked when the task updates it's progress or the progressTimer forces the progress UI to update */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	[viewController.progress setDoubleValue:(double)task.progress];
	
	//If we finished, set UI to "Finish" while the task finishes
	if (task.progress == 100) {
		[viewController.statusLabel	setStringValue:NSLocalizedString(@"Finishing…", nil)];
		[viewController.progress	setIndeterminate:YES];
		[viewController.progress	startAnimation:self];
		[viewController.partsLabel	setHidden:YES];
		[viewController lockView];
	}
}

/* Automatically invoked when the X-Button was clicked - user wants to cancel the task */
-(void)stopButtonClicked:(NSNotification *)notification {
	[self terminateTask];
}

#pragma mark -
#pragma mark Utility methods
@synthesize ETAFirstHalfFactor, ETALastRuntime, ETALastTotalRuntime;

/* Uses self.taskStartDate and the current progress to calculate the ETA based on EWMA (Exponentially weighted moving average) */
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
		
		ETALastRuntime		= runtime;
		ETALastTotalRuntime	= totalRuntime;
	} else { 
		/* Here we use EWMA, which takes old ETAs in account but still makes the current data point very significant. The formula:
		 x*Y(t) + (1-x)*S(t-1), where ...
		 x is a factor between 0 and 1. bigger x means that old ETA-measurements get meaningless faster
		 Y(t) is the current ETA (calculated by the same basic formula used above)
		 S(t-1) is the EWMA-based ETA that was calculated the last time
		 
		 Two additions are made to this formula:
		 1) x is dynamic. Since this method should calculate an ETA every 10 seconds, but isn't always called after exactly 10 seconds,
		 we calculate a weighting based on the actual time since the last ETA was calculated
		 2) Like explained above, the ETA gets calculated way too low at the beginning, which is why we multiply it by an additional factor
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
