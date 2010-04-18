//
//  RarfileViewController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define TaskViewStopButtonPressedNotification		@"TaskViewStopButtonPressedNotification"
#define TaskViewErrorOKButtonPressedNotification	@"TaskViewErrorOKButtonPressedNotification"




@class RAUStopButton;
@interface RAUTaskViewController : NSViewController {
	NSImageView			*fileIcon;
	NSImageView			*fileIconArchivingIndicator;
	NSImageView			*fileIconErrorIndicator;
	
	NSView				*normalView;
	NSTextField			*statusLabel;
	NSProgressIndicator	*progress;
	RAUStopButton		*stopButton;
	NSTextField			*partsLabel;

	NSView				*errorView;
	NSTextField			*errorMessage;
	NSButton			*errorOKButton;
}

@property (readwrite, assign)	IBOutlet	NSImageView			*fileIcon;
@property (readwrite, assign)	IBOutlet	NSImageView			*fileIconArchivingIndicator;
@property (readwrite, assign)	IBOutlet	NSImageView			*fileIconErrorIndicator;

@property (readwrite, assign)	IBOutlet	NSView				*normalView;
@property (readwrite, assign)	IBOutlet	NSTextField			*statusLabel;
@property (readwrite, assign)	IBOutlet	NSProgressIndicator	*progress;
@property (readwrite, assign)	IBOutlet	RAUStopButton		*stopButton;
@property (readwrite, assign)	IBOutlet	NSTextField			*partsLabel;

@property (readwrite, assign)	IBOutlet	NSView				*errorView;
@property (readwrite, assign)	IBOutlet	NSTextField			*errorMessage;
@property (readwrite, assign)	IBOutlet	NSButton			*errorOKButton;

-(IBAction)stopButtonPressed:(id)sender;
-(void)lockView;
-(void)showNormalView;
-(void)showErrorMessage:(NSString *)message;
-(IBAction)errorViewOKButtonPressed:(id)sender;

@end
