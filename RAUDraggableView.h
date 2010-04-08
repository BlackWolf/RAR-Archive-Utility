//
//  RAUDraggableView.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define FilesDraggedNotification	@"FilesDraggedNotification"


@interface RAUDraggableView : NSView {
	NSMutableArray *draggedFiles;
}

@property (readwrite, retain)	NSMutableArray	*draggedFiles;

@end
