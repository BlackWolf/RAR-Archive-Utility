//
//  Rartask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// A superclass for all rar-related tasks. Launches a task, grabs and parses the output and gives back the result

#import "RAUTask.h"
#import "Debug.h"


@implementation RAUTask
@synthesize task, fileHandle, currentFile, progress, result;

-(id)init {
	if (self = [super init]) {
		currentFile	=	0;
		progress	=	0;
		result		=	TaskResultNone;
	}
	return self;
}

/* Launches a task and prepares everything to grab the output and the taskTerminated notification */
-(void)taskWillLaunch {}
-(void)launchTask {
	self.task = [[NSTask alloc] init];
	
	[self taskWillLaunch];
	
	//Redirecting output to Pipe, then to NSFileHandle so we can catch it later
	NSPipe *pipe = [NSPipe pipe];
	[self.task setStandardOutput:pipe];
	[self.task setStandardError:pipe];
	self.fileHandle = [[pipe fileHandleForReading] retain];
	
	[self.task launch]; 
	
	[[NSNotificationCenter defaultCenter] //Listen to when the task terminates
	 addObserver:self
	 selector:@selector(taskDidTerminate:)
	 name:NSTaskDidTerminateNotification
	 object:self.task];
	
	[[NSNotificationCenter defaultCenter] //Listen to new output from the task
	 addObserver:self
	 selector:@selector(receivedNewOutput:)
	 name:NSFileHandleDataAvailableNotification
	 object:self.fileHandle];
	[self.fileHandle waitForDataInBackgroundAndNotify];
	
	[self taskDidLaunch];		
}
-(void)taskDidLaunch {}

/* Automatically invoked when new output is sent by the task. Gets the output and sends it to parseNewOutput: */
-(void)receivedNewOutput:(NSNotification *)notification {
	//Get the new output and check if it has any content (length > 0)
	NSData *availableData = [self.fileHandle availableData];
	if ([availableData length] == 0) return;
	NSString *output = [[NSString alloc] initWithData:availableData encoding:NSASCIIStringEncoding];
	
	[self parseNewOutput:output]; 
	
	[output release];
	[self.fileHandle waitForDataInBackgroundAndNotify]; //Make sure we still listen to upcoming output
}

/* Parses new output and sets instance variables accordingly */
-(void)parseNewOutput:(NSString *)output {

	/* First we need to remove all "Calculating control sums"-Blocks. They contain progress of calculating the control sum, which would
	 be mistakenly taken for the overall progress. Everything between "Calculating control sum" and the next "Creating archive" must go */
	
	static BOOL lastFinishedWithControlBlock = NO; //Takes care if an output finishes INSIDE a control block
	if (lastFinishedWithControlBlock == YES || [output rangeOfString:@"Calculating the control sum "].location != NSNotFound) {
		NSMutableString *newOutput = [NSMutableString stringWithCapacity:0];
		NSMutableArray *controlBlocks = [[output componentsSeparatedByString:@"Calculating the control sum "] mutableCopy];
		 
		//If we didn't finish in a control block, everything before the first control block is valid non-control-block stuff
		if (lastFinishedWithControlBlock == NO) {
			[newOutput appendString:[controlBlocks objectAtIndex:0]];
			[controlBlocks removeObjectAtIndex:0];
		}
		
		for (NSString *controlBlock in controlBlocks) {
			NSMutableArray *endOfControlBlock = [[output componentsSeparatedByString:@"Creating archive "] mutableCopy];
			if ([endOfControlBlock count] == 1) { //No "creating archive" was found - no end of the current control block was found
				lastFinishedWithControlBlock = YES;
			} else {
				[endOfControlBlock removeObjectAtIndex:0]; //everything before "creating archive", so still control block
				[newOutput appendString:[endOfControlBlock componentsJoinedByString:@" "]];
				lastFinishedWithControlBlock = NO;
			}
		}
		output = newOutput;
	}
	
	/* Send a Notification after we updated any of the instance variables. No need to send a Notification if result is set, because
	 the rartask will terminate after that anyways */
	
	if ([output rangeOfString:@"is not RAR archive"].location != NSNotFound
		|| [output rangeOfString:@"No such file or directory"].location != NSNotFound) {
		result = TaskResultArchiveInvalid;
	}
	
	if ([output rangeOfString:@"password incorrect ?"].location != NSNotFound) {
		result = TaskResultPasswordInvalid;
	}

	if ([output rangeOfString:@"%"].location != NSNotFound) { //New Progress in percent
		//Calculating control sum after each piece
		int newProgress = [self parseProgressFromString:output];
		if (newProgress > progress) {
			progress = newProgress;
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskHasUpdatedProgressNotification object:self];
		}
	}
	
	if ([output rangeOfString:@"All OK"].location != NSNotFound
		|| [output rangeOfString:@"Done"].location != NSNotFound) {
		result = TaskResultOK;
	}
}

/* This method simply parses a progress update from an output string */
-(int)parseProgressFromString:(NSString *)output {
	NSMutableArray *seperatedOutput = [[output componentsSeparatedByString:@"%"] mutableCopy];
	[seperatedOutput removeLastObject]; //Last string is just the remaining string after the last '%'
	
	int maxProgress = 0;
	for (NSString *progressElement in seperatedOutput) {
		if ([progressElement length] >= 2) {
			//We splitted at '%', so the last two digits before '%' should be the progress (there is no 100)
			progressElement = [progressElement substringFromIndex:([progressElement length]-2)]; 
			int readProgress = [progressElement intValue];
			if (readProgress > maxProgress) maxProgress = readProgress;
		}
	}
	return maxProgress+1; //Increase by 1, because unrar returns until it reaches 99%, but we want the UI to display 100%
}

/* A convenience method so we can nicely kill the task from anywhere. When the task actually terminates, taskDidTerminate: is
 automatically called to clean up after the task */
-(void)terminateTask {
	[self.task terminate];
}
	
/* Automatically called when the task terminates (either by hand or because it finished) */
-(void)taskDidTerminate:(NSNotification *)notification {
	//We wait half a second to make sure we processed all output (output sometimes arrives with a little lag)
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(didFinish) userInfo:nil repeats:NO];
}

/* Cleans up after the task in a new thread, then sends a notification that the task finished */
-(void)willFinish {}
-(void)didFinish {
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		[self willFinish];
		[self performSelectorOnMainThread:@selector(sendDidFinishNotification) withObject:nil waitUntilDone:YES];
	});
}
-(void)sendDidFinishNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskDidFinishNotification object:self];
}

/* Returns /path/name/. If that directory already exists, it appends a number to name until a non-existing directory is found */
-(NSString *)usableFilenameAtPath:(NSString *)path withName:(NSString *)name isDirectory:(BOOL)isDirectory {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *fileName;
	NSString *fileExtension;
	if (isDirectory == NO) { //Only take extensions into account for non-directories
		fileName = [name stringByDeletingPathExtension];
		fileExtension = [name pathExtension];
		if ([fileExtension length] > 0) fileExtension = [NSString stringWithFormat:@".%@",fileExtension];
	} else {
		fileName = name;
		fileExtension = @"";
	}
	NSString *usableDirectory = [path stringByAppendingPathComponent:name];
	
	if ([fileManager fileExistsAtPath:usableDirectory] == YES) {
		for (int i=1; [fileManager fileExistsAtPath:usableDirectory]; i++) {
			usableDirectory = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d%@", fileName, i, fileExtension]];
		}
	}
	
	return usableDirectory;
}
-(NSString *)usableFilenameAtPath:(NSString *)path withName:(NSString *)name {
	return [self usableFilenameAtPath:path withName:name isDirectory:NO];
}

-(NSString *)usableSuffixAtPath:(NSString *)path withNames:(NSArray *)names {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL allFilesFine = NO;
	int currentSuffix = 0;
	while (allFilesFine == NO) {
		allFilesFine = YES;
		for (NSString *name in names) {
			NSString *fileName = [name stringByDeletingPathExtension];
			NSString *fileExtension = [name pathExtension];
			NSString *fileMultipartExtension = [fileName pathExtension];
			
			if ([fileExtension length] > 0) fileExtension = [NSString stringWithFormat:@".%@",fileExtension];
			if ([fileMultipartExtension length] > 0) {
				fileName = [fileName stringByDeletingPathExtension];
				fileExtension = [NSString stringWithFormat:@".%@%@",fileMultipartExtension, fileExtension];
			}
			
			NSString *usableFilepath;
			if (currentSuffix == 0)	usableFilepath = [path stringByAppendingPathComponent:name];
			else					usableFilepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d%@", fileName, currentSuffix, fileExtension]];
		
			//if ([fileManager fileExistsAtPath:usableFilepath] == YES) {
				
				//if (currentSuffix == 0) currentSuffix = 1;
				while ([fileManager fileExistsAtPath:usableFilepath]) {
					allFilesFine = NO;
					currentSuffix++;
					
					usableFilepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d%@", fileName, currentSuffix, fileExtension]];
				}
			//}
		}
	}
	if (currentSuffix == 0) return @"";
	else					return [NSString stringWithFormat:@" %d", currentSuffix];
}

-(void)revealInFinder:(NSString *)path {
	//Tell finder to select path (via AppleScript). Don't select if path is the desktop or on the desktop
	NSString *pathToDesktop = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
	if ([path isEqualToString:pathToDesktop] == NO && [[path stringByDeletingLastPathComponent] isEqualToString:pathToDesktop] == NO) {
		//This C-Script converts from normal paths to HFS-Paths ("HD:Users:Me:Something") (found via google)
		CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, YES);
		CFStringRef hfsPath = CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
		
		NSString *scriptSourceCode = [NSString stringWithFormat:@"tell application \"Finder\" to reveal \"%@\"", hfsPath];
		if (url) CFRelease(url);
		if (hfsPath) CFRelease(hfsPath);
		
		NSAppleScript *appleScript = [[[NSAppleScript alloc] initWithSource:scriptSourceCode] autorelease];
		[appleScript executeAndReturnError:nil];
	}	
}

-(void)dealloc {
	/*
	if (self.task != nil) {
		if (self.task.isRunning == YES) [self.task terminate]; 
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:self.task];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self.fileHandle];
	}*/
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[task release];
	[fileHandle release];
	
	[super dealloc];
}

@end
