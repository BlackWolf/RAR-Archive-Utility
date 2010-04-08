//
//  RAR_Archive_UtilityAppDelegate.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"


@class RAUMainWindow, RAUTaskController, RAUExtractTaskController, RAUArchiveWizardController;
@interface RAR_Archive_UtilityAppDelegate : NSObject <NSApplicationDelegate, RAUTaskControllerDelegate> {
    RAUMainWindow						*window;
	NSView								*windowView;
	NSWindow							*passwordSheet;
	NSTextField							*passwordSheetHeading;
	NSTextField							*passwordSheetTextField;
	
	BOOL								applicationDidFinishLaunching;
	BOOL								terminateWhenDone;
	BOOL								terminating;
	NSMutableArray						*taskController;
	BOOL								passwordSheetIsShowing;
	RAUTaskController					*currentPasswordSheetTask;
	NSMutableArray						*waitingPasswordSheetTasks;
	RAUArchiveWizardController			*archiveWizard;
}

@property (assign)				IBOutlet	RAUMainWindow						*window;
@property (assign)				IBOutlet	NSView								*windowView;
@property (assign)				IBOutlet	NSWindow							*passwordSheet;
@property (assign)				IBOutlet	NSTextField							*passwordSheetHeading;
@property (assign)				IBOutlet	NSTextField							*passwordSheetTextField;

@property (readonly)						BOOL								applicationDidFinishLaunching;
@property (readonly)						BOOL								terminateWhenDone;
@property (readonly)						BOOL								terminating;
@property (readonly, assign)				NSMutableArray						*taskController;
@property (readonly)						BOOL								passwordSheetIsShowing;
@property (readonly, retain)				RAUTaskController					*currentPasswordSheetTask;
@property (readonly, assign)				NSMutableArray						*waitingPasswordSheetTasks;
@property (readonly, assign)				RAUArchiveWizardController			*archiveWizard;

-(void)addTaskController:(RAUTaskController *)newController;
-(void)taskControllerDidFinish:(RAUTaskController *)finishedController;
-(void)taskControllerNeedsPassword:(RAUTaskController *)needyController;
-(void)showPasswordSheet:(RAUTaskController *)needyController;
-(IBAction)passwordSheetPressedOK:(id)sender;
-(IBAction)passwordSheetPressedCancel:(id)sender;
-(void)dismissPasswordSheet;
-(IBAction)showArchiveWizard:(id)sender;
-(void)archiveWizardDidClose:(BOOL)successfully;

@end
