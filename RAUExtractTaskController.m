//
//  ExtractController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 12.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
// Subclass of RAUTaskController. Controlls an extraction task (unrarer)

#import "RAUExtractTaskController.h"
#import "RAURarfile.h"
#import "RAUTaskViewController.h"
#import "RAUExtractTask.h"


@implementation RAUExtractTaskController

-(id)initWithFile:(NSString *)filePath {
	if (self = [super init]) {
		ETAFirstHalfFactor = 1.7;
		[self createRarfileFromPath:filePath]; //Checks the file and invokes launchTask when done
		
		//Performing this after 0 seconds causes it to be performed AFTER the view was fully inizialized
		[self performSelector:@selector(initView) withObject:nil afterDelay:0];
	}
	return self;
}

/* Puts the icon of the extracted file into the view */
-(void)initView {
	[self.viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:self.file.fullPath]];
}

/* Called right before the task launches. Sets up the task and the UI */
-(void)taskWillLaunch {
	self.task = [[RAUExtractTask alloc] initWithFile:self.file mode:ExtractTaskModeExtract password:self.password];
	
	//Set GUI to "Unarchiving" status
	[self.viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Extracting \"%@.%@\"", nil), self.file.name, self.file.extension]];
	[self.viewController.progress setIndeterminate:NO]; 
	
	/*if (self.file.numberOfParts > 1) { //Multiparted rarfile - show the "part x of y" label
		[self.viewController.partsLabel	setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Part %d of %d", nil), 1, self.file.numberOfParts]];
	}*/
	[self progressWasUpdated:nil];
	[self.viewController.partsLabel setHidden:NO];
}

/* Automatically invoked when the Unrarer tells us the progress of the extraction was updated (% updated or new part started) */
-(void)progressWasUpdated:(NSNotification *)notification {
	NSString *runtimeString = [self getETAString];
	
	NSString *completeString;
	if (self.file.numberOfParts > 1) {
		NSString *partsString = [NSString stringWithFormat:NSLocalizedString(@"Part %d of %d", nil), self.task.currentFile, self.file.numberOfParts];
		completeString = [NSString stringWithFormat:@"%@ - %@", partsString, runtimeString];
	} else {
		completeString = runtimeString;
	}
		
	[self.viewController.partsLabel setStringValue:completeString];
	
	[super progressWasUpdated:notification];
}

-(void)dealloc {
	[super dealloc];
}
@end
