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
@synthesize fileIcon, fileIconArchivingIndicator, fileIconErrorIndicator;
@synthesize normalView, statusLabel, progress, stopButton, partsLabel;
@synthesize errorView, errorMessage, errorOKButton;

-(id)init {
	return [super initWithNibName:@"RarfileView" bundle:[NSBundle mainBundle]];
}

/* X-Button at the right side of the view was clicked */
-(IBAction)stopButtonPressed:(id)sender {
	[self.stopButton setEnabled:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskViewStopButtonPressedNotification object:self];
}

/* Prevents further changes to this view */
-(void)lockView {
	//We prevent changes by setting all UI-element-variables to nil. Therefore, the UI elements cannot be reached anymore
	self.fileIcon					= nil;
	self.fileIconArchivingIndicator	= nil;
	self.fileIconErrorIndicator		= nil;
	self.normalView					= nil;
	self.statusLabel				= nil;
	self.progress					= nil;
	self.partsLabel					= nil;
	self.errorView					= nil;
	self.errorMessage				= nil;
}

/* Replaces the normal progress view with an error view that shows an error message and an ok button */
-(void)showErrorMessage:(NSString *)message {
	[self.normalView setHidden:YES];
	
	[self.errorMessage setStringValue:message];
	[self.fileIconErrorIndicator setHidden:NO];
	[self.errorView setFrame:self.normalView.frame];
	[self.view addSubview:self.errorView];
	[[self.view window] makeFirstResponder:self.errorOKButton];
}

/* When the errorview was shown, this converts back to the normal progress UI */
-(void)showNormalView {
	[self.errorView removeFromSuperview];
	[self.fileIconErrorIndicator setHidden:YES];
	
	[self.normalView setHidden:NO];
}

/* Automatically called when the OK Button on the error view is pressed */
-(IBAction)errorViewOKButtonPressed:(id)sender {
	[self.errorOKButton setEnabled:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TaskViewErrorOKButtonPressedNotification object:self];
}

@end
