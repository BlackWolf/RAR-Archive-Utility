//
//  Rartask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Superclass for all Tasks. Gets some of the common methods in a central place
//

#import "RAUTask.h"


@implementation RAUTask

#pragma mark -
@synthesize currentFile, progress, result;

-(id)init {
	if (self = [super init]) {
		currentFile	=	0;
		progress	=	0;
		result		=	TaskResultNone;
	}
	return self;
}

-(void)willFinish {}
-(void)didFinish {
	//willFinish should contain cleanup stuff like copying files. We therefore do it in a seperate thread
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		[self willFinish];
		[self performSelectorOnMainThread:@selector(sendDidFinishNotification) withObject:nil waitUntilDone:YES];
	});
}

-(void)sendDidFinishNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskDidFinishNotification object:self];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[task		release];
	[fileHandle release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize task, fileHandle;

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
	
	//Listen to when the task terminates and to new output from the task
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDidTerminate:)
												 name:NSTaskDidTerminateNotification
											   object:self.task];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receivedNewOutput:)
												 name:NSFileHandleDataAvailableNotification
											   object:self.fileHandle];
	
	[self.fileHandle waitForDataInBackgroundAndNotify]; //Make sure fileHandle actually listens to new output
	
	[self taskDidLaunch];		
}
-(void)taskDidLaunch {}

-(void)terminateTask {
	[self.task terminate];
}

/* Automatically called when the task terminates (either by calling terminateTask or because it actually finished) */
-(void)taskDidTerminate:(NSNotification *)notification {
	//We wait half a second to make sure we processed all output (output sometimes arrives with a little lag)
	//After that, we tell the RAUTask to finish since the NSTask terminated
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(didFinish) userInfo:nil repeats:NO];
}

#pragma mark -
#pragma mark Parsing Output

/* Automatically invoked when new output is sent by the task */
-(void)receivedNewOutput:(NSNotification *)notification {
	//Get the new output and check if it has any content (length > 0)
	NSData *availableData = [self.fileHandle availableData];
	if ([availableData length] == 0) return;
	NSString *output = [[NSString alloc] initWithData:availableData encoding:NSASCIIStringEncoding];
	
	[self parseNewOutput:output]; 
	
	[output release];
	[self.fileHandle waitForDataInBackgroundAndNotify]; //Make sure we still listen to upcoming output
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
		}
		output = newOutput;
	}
	
	//Searching the output for different key phrases and performing actions (=setting variables) accordingly
	
	if ([output rangeOfString:@"is not RAR archive"].location != NSNotFound
		|| [output rangeOfString:@"No such file or directory"].location != NSNotFound) {
		result = TaskResultArchiveInvalid;
	}
	
	if ([output rangeOfString:@"password incorrect ?"].location != NSNotFound) {
		result = TaskResultPasswordInvalid;
	}

	if ([output rangeOfString:@"%"].location != NSNotFound) { 
		int newProgress = [self parseProgressFromString:output];
		if (newProgress > progress) { //Safety measure
			progress = newProgress;
#warning Sending a notification is senseless, we should directly invoke a method of RAUTaskController
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskHasUpdatedProgressNotification object:self];
		}
	}
	
	if ([output rangeOfString:@"All OK"].location != NSNotFound
		|| [output rangeOfString:@"Done"].location != NSNotFound) {
		result = TaskResultOK;
	}
}

/* This takes an output string and gets the current progress out of it (if in there) */
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
	return maxProgress+1; //Increase by 1, because unrar reaches a max of 99%, but we want the UI to display 100%
}

#pragma mark -
#pragma mark Utility methods

#warning we really need to rethink the whole renaming thing. at least recomment these methods
/* Returns a non-existing filename at path that is similair to name */
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
	
	//Try /path/name. If that already exists, append a number to name until we find a path that can be used
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

/* Returns a string, so that /path/name+string is a non-existing filename for all entries in names */
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
		
			while ([fileManager fileExistsAtPath:usableFilepath]) {
				allFilesFine = NO;
				currentSuffix++;
					
				usableFilepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d%@", fileName, currentSuffix, fileExtension]];
			}
		}
	}
	if (currentSuffix == 0) return @"";
	else					return [NSString stringWithFormat:@" %d", currentSuffix];
}

/* Uses an applescript to reveal path in finder */
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

@end
