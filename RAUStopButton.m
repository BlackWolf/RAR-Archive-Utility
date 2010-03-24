//
//  stopButton.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 29.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This class represents the X-Button on each TaskViewController. We need this to enable the imagechange when hovering over this button

#import "RAUStopButton.h"


@implementation RAUStopButton


/* Initialize the view after it is shown on the window. Set the initial images and the tracking rect for mouseovers */
- (void)viewDidMoveToWindow {
	[self setImage:				[NSImage imageNamed:@"stop"]];
	[self setAlternateImage:	[NSImage imageNamed:@"stopPressed"]];
	
	[self addTrackingRect:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height) 
					owner:self 
				 userData:nil 
			 assumeInside:NO];
}

/* Track when the mouse enters the button. If so, change to the hover-image */
- (void)mouseEntered:(NSEvent *)theEvent {
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stopHovered"]];
}

/* Track when the mouse leaves the button. If so, change for the normal image */
- (void)mouseExited:(NSEvent *)theEvent {
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stop"]];
}

@end
