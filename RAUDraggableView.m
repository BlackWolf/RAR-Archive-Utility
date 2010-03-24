//
//  RAUDraggableView.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RAUDraggableView.h"


@implementation RAUDraggableView
@synthesize draggedFiles;

/* Init */
-(void)awakeFromNib {
	self.draggedFiles = [[NSMutableArray alloc] initWithCapacity:0];
	
	//Register the view to accept incoming file drags
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; 
}

/* Automatically called when someone drags a file into the view. We need this method to report to the OS we accept the drag */
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The pastboard that contains the dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged item was a file
		return NSDragOperationCopy; //Doesn't really matter much, Copy is just the one used in most apps
    }
    return NSDragOperationNone; //No file? Permit the drag
}

/* Automatically called when the user actually drops something on our view (=releases the mouse button over it) */
-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard]; //The dragged elements
	
    if ([[pboard types] containsObject:NSFilenamesPboardType]) { //Dragged items were files
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

@end
