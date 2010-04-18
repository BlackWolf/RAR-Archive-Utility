//
//  RAR_Archive_UtilityAppDelegate.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"
#import "RAUPasswordWindow.h"
#import "RAUArchiveWizardController.h"




@class RAUMainWindow;
@interface RAR_Archive_UtilityAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, RAUTaskControllerDelegate, RAUPasswordWindowDelegate, RAUArchiveWizardControllerDelegate> {
    RAUMainWindow				*window;
	NSView						*windowView;
	BOOL						applicationDidFinishLaunching;
	BOOL						terminateWhenDone;
	BOOL						terminating;
	NSMutableArray				*taskController;
	RAUPasswordWindow			*passwordWindow;
	BOOL						passwordWindowIsShowing;
	RAUTaskController			*passwordWindowCurrentTask;
	NSMutableArray				*passwordWindowWaitingTasks;
	RAUArchiveWizardController	*archiveWizard;
}

@property (readwrite, assign)	IBOutlet	RAUMainWindow		*window;
@property (readwrite, assign)	IBOutlet	NSView				*windowView;
@property (readonly)						BOOL				applicationDidFinishLaunching;
@property (readwrite)						BOOL				terminateWhenDone;
@property (readonly)						BOOL				terminating;
@property (readonly, retain)				NSMutableArray		*taskController;
@property (readwrite, assign)	IBOutlet	RAUPasswordWindow	*passwordWindow;

-(IBAction)showArchiveWizard:(id)sender;

@end
