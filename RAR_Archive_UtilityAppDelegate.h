//
//  RAR_Archive_UtilityAppDelegate.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RAUMainWindow, RAUTaskController, RAUExtractTaskController, RAUArchiveWizardController;
@interface RAR_Archive_UtilityAppDelegate : NSObject <NSApplicationDelegate> {
    RAUMainWindow						*window;
	NSView								*windowView;
	NSWindow							*passwordSheet;
	NSTextField							*passwordSheetHeading;
	NSTextField							*passwordInput;
	NSTextField							*debugLabel;
	
	BOOL								applicationDidFinishLaunching;
	BOOL								terminateWhenDone;
	BOOL								passwordSheetIsShowing;
	NSMutableArray						*taskController;
	RAUExtractTaskController			*passwordSheetController;
	NSMutableArray						*waitingForPasswordSheet;
	RAUArchiveWizardController			*archiveWizard;
	BOOL								terminating;
}

@property (assign)				IBOutlet	RAUMainWindow						*window;
@property (assign)				IBOutlet	NSView								*windowView;
@property (assign)				IBOutlet	NSWindow							*passwordSheet;
@property (assign)				IBOutlet	NSTextField							*passwordSheetHeading;
@property (assign)				IBOutlet	NSTextField							*passwordInput;
@property (assign)				IBOutlet	NSTextField							*debugLabel;

@property (readonly)						BOOL								applicationDidFinishLaunching;
@property (readonly)						BOOL								terminateWhenDone;
@property (readonly)						BOOL								passwordSheetIsShowing;
@property (readwrite, assign)				NSMutableArray						*taskController;
@property (readwrite, assign)				RAUExtractTaskController			*passwordSheetController;
@property (readwrite, assign)				NSMutableArray						*waitingForPasswordSheet;
@property (readwrite, assign)				RAUArchiveWizardController			*archiveWizard;
@property (readonly)						BOOL								terminating;

-(void)addTaskController:(RAUTaskController *)newController;
-(void)passwordSheetRequested:(NSNotification *)notification;
-(void)showPasswordSheet:(RAUExtractTaskController *)protectedFile;
-(IBAction)passwordSheetPressedOK:(id)sender;
-(IBAction)passwordSheetPressedCancel:(id)sender;
-(void)dismissPasswordSheet;
-(void)taskControllerDidFinish:(NSNotification *)notification;
-(IBAction)showArchiveWizard:(id)sender;
-(void)archiveWizardDidClose:(BOOL)successfully;

@end
