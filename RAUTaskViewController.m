//
//  RarfileViewController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Controller of a view belonging to a Archiving/Extracting Task

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

/* X-Button was clicked, user wants to cancel the task belonging to this viewController - but we don't take care of that */
-(IBAction)stopButtonClicked:(id)sender {
	RAUStopButton *stopButton = (RAUStopButton *)sender;
	[stopButton setEnabled:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskViewStopButtonClickedNotification object:self];
}

@end
