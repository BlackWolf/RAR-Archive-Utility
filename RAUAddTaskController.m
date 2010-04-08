//
//  RAUAddTaskController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import "RAUAddTaskController.h"
#import "RAUAddTask.h"
#import "RAUTaskViewController.h"

@implementation RAUAddTaskController

#pragma mark -
@synthesize filesToArchive, compressionLevelArgument;

-(id)initWithFilesToArchive:(NSArray *)files inRarfile:(RAUPath *)aRarfile {
	if (self = [super init]) {
		filesToArchive				= [files copy];
		self.rarfilePath			= aRarfile; //sets rarfile and checks it
		compressionLevelArgument	= 3;
		ETAFirstHalfFactor			= 1.45;
	}
	return self;
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	[super initView];
	
	//Show self.file's icon together with the archiving indicator
	[viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFileType:@"rar"]];
	[viewController.fileIconArchivingIndicator setHidden:NO];
}

-(void)didFinish {
	[super didFinish];
}

-(void)dealloc {
	[filesToArchive	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The RAUAddTask
@synthesize addTask;

-(RAUAddTask *)addTask {
	return (RAUAddTask *)task;
}

-(void)taskWillLaunch {
	task = [[RAUAddTask alloc] initWithFilesToArchive:filesToArchive withRarfile:rarfile];
	[self.addTask setPasswordArgument:passwordArgument];
	[self.addTask setCompressionLevelArgument:compressionLevelArgument];
}

/* Automatically invoked when the Task updates its progress */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	if (self.addTask.numberOfFiles > 0) { 
		[viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Archiving %d files", nil), self.addTask.numberOfFiles]];
		[viewController.progress	setIndeterminate:NO]; 
		[viewController.partsLabel	setHidden:NO];
	
		NSString *runtimeString = [self getETAString];
		
		NSString *completeString;
		if (self.addTask.numberOfFiles > 1) { //more than one file - we need the "file x of y label"
			//numberOfFiles can be wrong. Even if it is, never show something like "File 11 of 10"
			int numberOfFiles = self.addTask.numberOfFiles;
			if (self.addTask.currentFile > numberOfFiles) numberOfFiles = self.addTask.currentFile;
			
			NSString *fileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d", nil), self.addTask.currentFile, numberOfFiles];
			completeString = [NSString stringWithFormat:@"%@ - %@", fileString, runtimeString];
		} else {
			completeString = runtimeString;
		}
		[viewController.partsLabel setStringValue:completeString];
		
		[super taskProgressWasUpdated:updatedTask];
	}
}

@end
