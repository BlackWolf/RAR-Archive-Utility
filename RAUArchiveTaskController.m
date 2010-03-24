//
//  ArchiveController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 12.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Subclass of RAUTaskController. Controls an archieving task (rarer)

#import "RAUArchiveTaskController.h"
#import "RAURarfile.h"
#import "RAUTaskViewController.h"
#import "RAUArchiveTask.h"
#import "Debug.h"


@implementation RAUArchiveTaskController
@synthesize files, pathToNewRarfile, compressionLevel, splitSize, totalFilesToArchive;

-(id)initExistingRarfile:(NSString *)existingRarfile withFilesToAdd:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression {
	if (self = [super init]) {
		ETAFirstHalfFactor = 1.45;
		self.files = filesToArchive;
		self.password = filePassword;
		compressionLevel = compression;
		
		//Performing this after 0 seconds causes it to be performed AFTER the view was fully inizialized
		[self performSelector:@selector(initView) withObject:nil afterDelay:0];
		
		if (existingRarfile != nil) {
			[self createRarfileFromPath:existingRarfile]; //Checks the file and invokes launchTask when done
		} else {
			[self performSelector:@selector(launchTask) withObject:nil afterDelay:0];
		}
	}
	return self;
}
-(id)initExistingRarfile:(NSString *)existingRarfile withFilesToAdd:(NSArray *)filesToArchive {
	return [self initExistingRarfile:existingRarfile withFilesToAdd:filesToArchive password:nil compressionLevel:3];
}
-(id)initNewRarfile:(NSString *)newRarfile withFiles:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression pieceSize:(int)pieceSize {
	if (self = [super init]) {
		self.pathToNewRarfile = newRarfile;
		self.files = filesToArchive;
		self.password = filePassword;
		compressionLevel = compression;
		splitSize = pieceSize;
		
		//Performing this after 0 seconds causes it to be performed AFTER the view was fully inizialized
		[self performSelector:@selector(initView) withObject:nil afterDelay:0];
		[self performSelector:@selector(launchTask) withObject:nil afterDelay:0];
	}
	return self;
}
-(id)initNewRarfile:(NSString *)newRarfile withFiles:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression {
	return [self initNewRarfile:newRarfile withFiles:filesToArchive password:filePassword compressionLevel:compression pieceSize:0];
}
-(id)initNewRarfileWithFiles:(NSArray *)filesToArchive {
	return [self initNewRarfile:nil withFiles:filesToArchive password:nil compressionLevel:3 pieceSize:0];
}

/* Places a raricon next to the archiving progress and displays the green "archiving-arrow" */
-(void)initView {
	[self.viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFileType:@"rar"]];
	[self.viewController.fileIconArchivingIndicator setHidden:NO];
}

/* Called before the task launches. We create the archiving task here */
-(void)taskWillLaunch {
	if (self.file != nil) { //We want to add something to a rarfile
		self.task = [[RAUArchiveTask alloc] initWithFiles:self.files rarfileToModify:self.file password:self.password compressionLevel:compressionLevel];
	} else { //We want to create a new rarfile
		self.task = [[RAUArchiveTask alloc] initWithFiles:self.files rarfileToCreate:self.pathToNewRarfile password:self.password compressionLevel:compressionLevel splitIntoPiecesOfSize:splitSize];
	}
	
	//Count the files we are archiving (including subfolders). Since this can take a while, do it in a seperate thread
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDirectoryEnumerator *dirEnumerator;
		totalFilesToArchive = 0;
		
		for (NSString *fileToArchive in self.files) {
			dirEnumerator = [fileManager enumeratorAtPath:fileToArchive];
			totalFilesToArchive += [[dirEnumerator allObjects] count]+1;
		}
		
		//Set GUI to "Archiving" status
		[self.viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Archiving %d files", nil), totalFilesToArchive]];
		[self.viewController.progress setIndeterminate:NO]; 
		
		[self progressWasUpdated:nil];
		[self.viewController.partsLabel setHidden:NO];
	});
}

/* Automatically invoked when the Unrarer tells us the progress of the extraction was updated (% updated or new part started) */
-(void)progressWasUpdated:(NSNotification *)notification {
	NSString *runtimeString = [self getETAString];
						   
	int currentPart;
	if (self.task.currentFile > self.totalFilesToArchive) currentPart = self.totalFilesToArchive;
	else currentPart = self.task.currentFile;
	
	NSString *fileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d", nil), self.task.currentFile, totalFilesToArchive];
	
	[self.viewController.partsLabel setStringValue:[NSString stringWithFormat:@"%@ - %@", fileString, runtimeString]];
													
	[super progressWasUpdated:notification];
}

-(void)dealloc {
	[files release];
	
	[super dealloc];
}
@end
