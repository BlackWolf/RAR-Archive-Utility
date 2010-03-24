//
//  MainWindow.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 29.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// The main window on which all TaskViewController.view's are displayed (one for every Task). We need to subclass NSWindow to make
// sure the expand/collapse animations are done properly and that files can be dragged onto the window.
// Note: The code to enable dragging was pretty much taken from apple's documentation, which is why it's a little overcommented

#import "RAUMainWindow.h"
#import "Debug.h"


@implementation RAUMainWindow
@synthesize introLabel;

/* Init */
-(void)awakeFromNib {
	//Register the main window to accept incoming file drags
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; 
}

/* Automatically called when someone drags a file into the window. We need this method to report to the OS we accept the drag */
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The pastboard that contains the dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged item was a file
		 return NSDragOperationCopy; //Doesn't really matter much, Copy is just the one used in most apps
    }
    return NSDragOperationNone; //No file? Permit the drag
}

/* Automatically called when the user actually drops something on our app (=releases the mouse button over our app) */
-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged items were files
		//Get the files and tell our app delegate to open them (which starts extracting/archiving tasks)
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		[[[NSApplication sharedApplication] delegate] application:nil openFiles:files];
    }
	
    return YES;
}

/* Sets the duration for a resize (expand/collapse) animation */
-(NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
	return 0.55;
}

/* Expands the window vertically */
-(void)expandBy:(int)expandBy animate:(BOOL)animate {
	NSRect windowFrame = self.frame;
	NSRect newWindowFrame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y-expandBy, 
									   windowFrame.size.width, windowFrame.size.height+expandBy); 
	
	[self setFrame:newWindowFrame
		   display:YES 
		   animate:animate];
}
-(void)expandBy:(int)expandBy {
	[self expandBy:expandBy animate:YES];
}

/* Collapses the window vertically */
-(void)collapseBy:(int)collapseBy animate:(BOOL)animate {
	NSRect windowFrame = self.frame;
	NSRect newWindowFrame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y+collapseBy, 
									   windowFrame.size.width, windowFrame.size.height-collapseBy);
	
	[self setFrame:newWindowFrame
		   display:YES 
		   animate:animate];
}
-(void)collapseBy:(int)collapseBy {
	[self collapseBy:collapseBy animate:YES];
}

/* Automatically called when the user clicks the close-button of the window. If the user closes the main window, the app should terminate */
- (BOOL)windowShouldClose:(id)sender {
	[NSApp terminate:nil];
	
	return YES;
}

-(void)dealloc {
	[introLabel	release];
	
	[super dealloc];
}

@end
