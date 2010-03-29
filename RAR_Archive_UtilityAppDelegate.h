//
//  RAR_Archive_UtilityAppDelegate.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RAUMainWindow, RAUTaskController, RAUExtractTaskController, RAUArchiveWizardController;
@interface RAR_Archive_UtilityAppDelegate : NSObject <NSApplicationDelegate> {
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
	RAUExtractTaskController			*currentPasswordSheetTask;
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
@property (readwrite, assign)				NSMutableArray						*taskController;
@property (readonly)						BOOL								passwordSheetIsShowing;
@property (readwrite, assign)				RAUExtractTaskController			*currentPasswordSheetTask;
@property (readwrite, assign)				NSMutableArray						*waitingPasswordSheetTasks;
@property (readwrite, assign)				RAUArchiveWizardController			*archiveWizard;

-(void)addTaskController:(RAUTaskController *)newController;
-(void)taskControllerDidFinish:(NSNotification *)notification;
-(void)passwordSheetRequested:(NSNotification *)notification;
-(void)showPasswordSheet:(RAUExtractTaskController *)protectedFile;
-(IBAction)passwordSheetPressedOK:(id)sender;
-(IBAction)passwordSheetPressedCancel:(id)sender;
-(void)dismissPasswordSheet;
-(IBAction)showArchiveWizard:(id)sender;
-(void)archiveWizardDidClose:(BOOL)successfully;

@end
