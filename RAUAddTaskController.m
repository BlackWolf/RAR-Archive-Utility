//
//  RAUAddTaskController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This creates the controller for an RAUAddTask. With this you can add files to an existing rarfile. This controller
// also gives you an UI that is always updated to the current state of the task. 
//

#import "RAUAddTaskController.h"
#import "RAUAddTask.h"
#import "RAUTaskViewController.h"




@interface RAUAddTaskController ()
@property (readwrite, copy)	NSArray	*filesToArchive;
@end
#pragma mark -




@implementation RAUAddTaskController
#pragma mark -
@synthesize filesToArchive, compressionLevelArgument;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive inRarfile:(RAUPath *)_rarfilePath {
	if (self = [super init]) {
		self.ETAFirstHalfFactor			= 1.45;
		self.filesToArchive				= _filesToArchive;
		self.rarfilePath				= _rarfilePath; //sets rarfile and checks it
		self.compressionLevelArgument	= 3;
	}
	return self;
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	[super initView];
	
	//Show self.file's icon together with the archiving indicator
	[self.viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFileType:@"rar"]];
	[self.viewController.fileIconArchivingIndicator setHidden:NO];
}

-(void)didFinish {
	[super didFinish];
}

-(void)dealloc {
	self.filesToArchive	= nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark The RAUAddTask
@synthesize addTask;

-(RAUAddTask *)addTask {
	return (RAUAddTask *)self.task;
}

-(void)taskWillLaunch {
	RAUAddTask *_task = [[RAUAddTask alloc] initWithFilesToArchive:filesToArchive withRarfile:rarfile];
	self.task = _task;
	[_task release];
	
	[self.addTask setPasswordArgument:self.passwordArgument];
	[self.addTask setCompressionLevelArgument:self.compressionLevelArgument];
}

/* Automatically invoked when the Task updates its progress */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	if (self.addTask.numberOfFiles > 0) { 
		[self.viewController.progress	setIndeterminate:NO]; 
		[self.viewController.partsLabel	setHidden:NO];
	
		NSString *runtimeString = [self getETAString];
		
		NSString *completeString;
		if (self.addTask.numberOfFiles > 1) { //more than one file - we need the "file x of y label"
			[self.viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Archiving %d files", nil), self.addTask.numberOfFiles]];
			
			//numberOfFiles can be wrong. Even if it is, never show something like "File 11 of 10"
			int numberOfFiles = self.addTask.numberOfFiles;
			if (self.addTask.currentFile > numberOfFiles) numberOfFiles = self.addTask.currentFile;
			
			NSString *fileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d", nil), self.addTask.currentFile, numberOfFiles];
			completeString = [NSString stringWithFormat:@"%@ - %@", fileString, runtimeString];
		} else {
			[self.viewController.statusLabel setStringValue:NSLocalizedString(@"Archiving 1 file", nil)];
			
			completeString = runtimeString;
		}
		[self.viewController.partsLabel setStringValue:completeString];
		
		[super taskProgressWasUpdated:updatedTask];
	}
}

@end
