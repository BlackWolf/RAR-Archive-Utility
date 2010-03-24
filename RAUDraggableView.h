//
//  RAUDraggableView.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define FilesDraggedNotification	@"FilesDraggedNotification"
@interface RAUDraggableView : NSView {
	NSMutableArray *draggedFiles;
}

@property (readwrite, assign)	NSMutableArray	*draggedFiles;

@end
