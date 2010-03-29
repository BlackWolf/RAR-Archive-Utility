//
//  RarfileViewController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This controls a view that belongs to a extraction/archiving task
//

#import "RAUTaskViewController.h"
#import "RAUStopButton.h"


@implementation RAUTaskViewController
@synthesize fileIcon, fileIconArchivingIndicator, statusLabel, progress, partsLabel;

-(void)loadView {
	[super loadView];

	//Set the view to "Preparing" state (before the extraction begins, while checking out the file etc.)
	[self.statusLabel	setStringValue:NSLocalizedString(@"Preparing…", nil)];
	[self.progress		setIndeterminate:YES];
	[self.progress		startAnimation:self];
}

/* X-Button at the right side of the view was clicked */
-(IBAction)stopButtonClicked:(id)sender {
	RAUStopButton *stopButton = (RAUStopButton *)sender;
	[stopButton setEnabled:NO];
	
	//Just send a notification that the button was clicked - we don't take care of what to do then here
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskViewStopButtonClickedNotification object:self];
}

@end
