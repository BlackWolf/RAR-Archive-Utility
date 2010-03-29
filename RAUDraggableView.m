//
//  RAUDraggableView.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// A subclass of NSView that accepts files dragged into it. Also keeps an array of all the files dragged into it
//

#import "RAUDraggableView.h"


@implementation RAUDraggableView
@synthesize draggedFiles;

-(void)awakeFromNib {
	self.draggedFiles = [[NSMutableArray alloc] initWithCapacity:0];
	
	//Register the view to accept drags
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; 
}

/* Automatically called when someone drags a file into the view. We need this method to report to the OS we accept the drag */
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The pastboard that contains the dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged item was a file
		return NSDragOperationCopy; 
    }
    return NSDragOperationNone; //No file? Permit the drag
}

/* Automatically called when the user releases drags over our view */
-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged items were files
		//Get the files and put them in self.draggedFiles if they are not already in there
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		for (NSString *file in files) {
			BOOL fileAlreadyExists = NO;
			for (NSString *existingFile in self.draggedFiles) {
				if ([existingFile isEqualToString:file] == YES) {
					fileAlreadyExists = YES;
					break;
				}
			}
			if (fileAlreadyExists == NO) [self.draggedFiles addObject:file];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:FilesDraggedNotification object:self];
    }
	
    return YES;
}

-(void)dealloc {
	[draggedFiles release];
	
	[super dealloc];
}

@end
