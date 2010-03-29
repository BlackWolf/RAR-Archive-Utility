//
//  stopButton.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 29.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This class represents the X-Button on each TaskView. We subclass NSButton to enable the imagechange when hovering over this button
//

#import "RAUStopButton.h"


@implementation RAUStopButton

/* Init. Called after the button is properly initialized (so we can change its appearance) */
- (void)viewDidMoveToWindow {
	[self setImage:				[NSImage imageNamed:@"stop"]];
	[self setAlternateImage:	[NSImage imageNamed:@"stopPressed"]];
	
	//When the user enters this rect, mouseEntered: is called
	[self addTrackingRect:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height) 
					owner:self 
				 userData:nil 
			 assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stopHovered"]];
}

- (void)mouseExited:(NSEvent *)theEvent {
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stop"]];
}

@end
