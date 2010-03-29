//
//  ExtractController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 12.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Subclass of RAUTaskController. Controls an extraction task
//

#import "RAUExtractTaskController.h"
#import "RAURarfile.h"
#import "RAUTaskViewController.h"
#import "RAUExtractTask.h"


@implementation RAUExtractTaskController

#pragma mark -

-(id)initWithFile:(NSString *)filePath {
	if (self = [super init]) {
		ETAFirstHalfFactor = 1.7;
		[self createRarfileFromPath:filePath]; //Checks the file and invokes launchTask when done
		
		[self performSelector:@selector(initView) withObject:nil afterDelay:0];
	}
	return self;
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	//Show self.file's icon
	[self.viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:self.file.fullPath]];
}

#pragma mark -
#pragma mark The RAUExtractTask

-(void)taskWillLaunch {
	//Overwrite the standard RAUTask in self.task with an RAUExtractTask
	self.task = [[RAUExtractTask alloc] initWithFile:self.file mode:ExtractTaskModeExtract password:self.password];
	
	//Set GUI to "Extracting" status
	[self.viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Extracting \"%@.%@\"", nil), self.file.name, self.file.extension]];
	[self.viewController.progress setIndeterminate:NO]; 
	
	[self progressWasUpdated:nil];
	[self.viewController.partsLabel setHidden:NO];
}

/* Automatically invoked when the Task updates its progress */
-(void)progressWasUpdated:(NSNotification *)notification {
	NSString *runtimeString = [self getETAString];
	
	NSString *completeString;
	if (self.file.numberOfParts > 1) { //Multiple parts - we need the "Part x of y" string
		NSString *partsString = [NSString stringWithFormat:NSLocalizedString(@"Part %d of %d", nil), self.task.currentFile, self.file.numberOfParts];
		completeString = [NSString stringWithFormat:@"%@ - %@", partsString, runtimeString];
	} else { //Single part - only show ETA
		completeString = runtimeString;
	}
	[self.viewController.partsLabel setStringValue:completeString];
	
	[super progressWasUpdated:notification];
}

@end
