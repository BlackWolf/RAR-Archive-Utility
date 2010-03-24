//
//  RarfileViewController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define TaskViewStopButtonClickedNotification	@"TaskViewStopButtonClickedNotification"
@interface RAUTaskViewController : NSViewController {
	NSImageView			*fileIcon;
	NSImageView			*fileIconArchivingIndicator;
	NSTextField			*statusLabel;
	NSProgressIndicator	*progress;
	NSTextField			*partsLabel;
}

@property (assign)	IBOutlet	NSImageView			*fileIcon;
@property (assign)	IBOutlet	NSImageView			*fileIconArchivingIndicator;
@property (assign)	IBOutlet	NSTextField			*statusLabel;
@property (assign)	IBOutlet	NSProgressIndicator	*progress;
@property (assign)	IBOutlet	NSTextField			*partsLabel;

-(IBAction)stopButtonClicked:(id)sender;

@end
