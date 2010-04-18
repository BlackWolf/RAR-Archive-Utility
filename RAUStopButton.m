//
//  stopButton.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 29.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This class represents the X-Button on a TaskView. We subclass NSButton to enable the imagechange when hovering over this button
//

#import "RAUStopButton.h"




@interface RAUStopButton ()
@property (readwrite)	BOOL	mouseIn;
@end
#pragma mark -




@implementation RAUStopButton
#pragma mark -
@synthesize mouseIn;

/* Init. Called after the button is properly initialized (so we can change its appearance) */
-(void)viewDidMoveToWindow {
	[self setImage:				[NSImage imageNamed:@"stop"]];
	[self setAlternateImage:	[NSImage imageNamed:@"stopPressed"]];
	
	//When the user enters this rect, mouseEntered: is called
	[self addTrackingRect:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height) 
					owner:self 
				 userData:nil 
			 assumeInside:NO];
	
	//Check if the mouse is inside the button and set the initial value of mouseIn
	NSPoint mousePosition = [self.window mouseLocationOutsideOfEventStream];
	self.mouseIn = NSPointInRect(mousePosition, self.frame);
	if (self.mouseIn == YES) [self mouseEntered:nil]; else [self mouseExited:nil];
}

-(void)mouseEntered:(NSEvent *)theEvent {
	self.mouseIn = YES;
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stopHovered"]];
}

-(void)mouseExited:(NSEvent *)theEvent {
	self.mouseIn = NO;
	if (self.isEnabled == YES)
		[self setImage:[NSImage imageNamed:@"stop"]];
}

/* If the button is disabled, lower its opacity */
-(void)setEnabled:(BOOL)value {
	[super setEnabled:value];
	
	if (value == YES) {
		[self setAlphaValue:1.0];
		if (self.mouseIn == YES) [self mouseEntered:nil]; else [self mouseExited:nil];
	}
	else {
		[self setAlphaValue:0.3];
	}
}

/* The button does not accept mouseclicks, if the window it is on is inactive and the click that activates it is over the button */
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return NO;
}

@end
