//
//  RAUTask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 31.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// An RAUTask is actually just a wrapper for an NSTask, providing functionality for the NSTask in the context of the RAU. This superclass
// brings together some methods common to all RAUTasks, it should not be instanciated directly, only via subclasses of it
//

#import "RAUTask.h"
#import "RAUTaskPrivates.h"




@implementation RAUTask

#pragma mark -
@synthesize delegate, progress, result;

-(id)init {
	if (self = [super init]) {
		self.progress	=  0;
		self.result		= TaskResultNone;
		self.task		= nil;
	}
	return self;
}

/* didFinish is called when the NSTask, and therefore the RAUTask, did its job */
-(void)willFinish {}
-(void)didFinish {
	[self willFinish];
	
	if (self.task.terminationStatus == 0)	self.result = TaskResultOK;
	else									self.result = TaskResultFailed;

	[delegate taskDidFinish:self];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.task = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize task;

-(void)taskWillLaunch {}
-(void)launchTask {
	NSTask *_task = [[NSTask alloc] init];
	self.task = _task;
	[_task release];
	
	[self taskWillLaunch];
	
	//Redirecting output to Pipe, then to NSFileHandle so we can catch it later
	NSPipe *pipe = [NSPipe pipe];
	[self.task setStandardOutput:pipe];
	[self.task setStandardError:pipe];
	NSFileHandle *fileHandle = [pipe fileHandleForReading];
	
	[self.task launch]; 
	
	//Listen to when the task terminates and to new output from the task
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDidTerminate:)
												 name:NSTaskDidTerminateNotification
											   object:self.task];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receivedNewOutput:)
												 name:NSFileHandleDataAvailableNotification
											   object:fileHandle];
	
	[fileHandle waitForDataInBackgroundAndNotify]; //Make sure fileHandle actually listens to new output
	
	[self taskDidLaunch];	
}
-(void)taskDidLaunch {}

-(void)terminateTask {
	[self.task terminate];
}

/* Automatically called when the NSTask terminated (either by calling terminateTask or because it actually finished) */
-(void)taskDidTerminate:(NSNotification *)notification {
	//We wait half a second to make sure we processed all output (output sometimes arrives with a little lag)
	[self performSelector:@selector(didFinish) withObject:nil afterDelay:0.5];
}

#pragma mark -
#pragma mark Parsing Output

/* Automatically invoked when new output is sent by the NSTask */
-(void)receivedNewOutput:(NSNotification *)notification {
	//Get the new output and check if it has any content (length > 0)
	NSFileHandle *fileHandle = [notification object];
	NSData *availableData = [fileHandle availableData];
	if ([availableData length] == 0) return;
	NSString *output = [[NSString alloc] initWithData:availableData encoding:NSASCIIStringEncoding];
	
	[self parseNewOutput:output]; 
	
	[output release];
	[fileHandle waitForDataInBackgroundAndNotify]; //Make sure we still listen to upcoming output
}

-(void)parseNewOutput:(NSString *)output {
	/* First we need to remove all "Calculating control sums"-Blocks. They contain progress of calculating some control sum, which would
	 be mistakenly taken for the overall progress. Everything between "Calculating control sum" and the next "Creating archive" must go */
	
	static BOOL lastFinishedInControlBlock = NO; //Takes care if output finishes INSIDE a control block
	if (lastFinishedInControlBlock == YES || [output rangeOfString:@"Calculating the control sum "].location != NSNotFound) {
		NSMutableString	*newOutput		= [NSMutableString stringWithCapacity:0];
		NSMutableArray	*controlBlocks	= [[output componentsSeparatedByString:@"Calculating the control sum "] mutableCopy];
		
		//If we didn't finish in a control block, everything before the first control block is valid non-control-block stuff
		if (lastFinishedInControlBlock == NO) {
			[newOutput appendString:[controlBlocks objectAtIndex:0]];
			[controlBlocks removeObjectAtIndex:0];
		}
		
		for (NSString *controlBlock in controlBlocks) {
			NSMutableArray *endOfControlBlock = [[output componentsSeparatedByString:@"Creating archive "] mutableCopy];
			if ([endOfControlBlock count] == 1) { //No "creating archive" was found - no end of the current control block was found
				lastFinishedInControlBlock = YES;
			} else {
				[endOfControlBlock removeObjectAtIndex:0]; //everything before "creating archive", so still control block
				[newOutput appendString:[endOfControlBlock componentsJoinedByString:@" "]];
				lastFinishedInControlBlock = NO;
			}
			[endOfControlBlock release];
		}
		output = newOutput;
		
		[controlBlocks release];
	}
	
	//Searching the output for different key phrases and performing actions (=setting variables) accordingly
	
	if ([output rangeOfString:@"%"].location != NSNotFound) { 
		int newProgress = [self parseProgressFromString:output];
		if (newProgress > self.progress) { //Safety measure
			self.progress = newProgress;
			[delegate taskProgressWasUpdated:self];
		}
	}
}

/* This takes an output string and gets the current progress out of it (if in there) */
-(int)parseProgressFromString:(NSString *)output {
	NSMutableArray *seperatedOutput = [[output componentsSeparatedByString:@"%"] mutableCopy];
	[seperatedOutput removeLastObject]; //Last string is just the remaining string after the last '%'
	
	int maxProgress = 0;
	for (NSString *progressElement in seperatedOutput) {
		if ([progressElement length] >= 2) {
			//We splitted at '%', so the last three digits before '%' should be the progress (might be some spaces in it as well)
			progressElement = [progressElement substringFromIndex:([progressElement length]-3)]; 
			int readProgress = [progressElement intValue];
			if (readProgress > maxProgress) maxProgress = readProgress;
		}
	}
	
	[seperatedOutput release];
	
	//In rare cases the rartask displays a progress of 100%, but most times it displays a max of 99%. Since we want the UI to display
	//100% every time, we increase the parsed progress by 1, unless it already is 100%
	return (maxProgress == 100) ? maxProgress : maxProgress+1; 
}

@end