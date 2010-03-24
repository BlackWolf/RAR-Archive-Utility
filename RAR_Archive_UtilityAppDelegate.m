//
//  RAR_Archive_UtilityAppDelegate.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
// Main application file. Receives a message when files are opened or dragged into the main window. Creates a TaskController for
// every extracting or archiving task we want to do and manages the main window and the TaskView's on it. 

#import "RAR_Archive_UtilityAppDelegate.h"
#import "RAUMainWindow.h"
#import "RAUExtractTaskController.h"
#import "RAUArchiveTaskController.h"
#import "RAUTaskViewController.h"
#import "RAURarfile.h"
#import "RAUArchiveWizardController.h"
#import "Debug.h"


@implementation RAR_Archive_UtilityAppDelegate
@synthesize window, windowView, passwordSheet, passwordSheetHeading, passwordInput, debugLabel;
@synthesize applicationDidFinishLaunching, terminateWhenDone, passwordSheetIsShowing, taskController, passwordSheetController, waitingForPasswordSheet, archiveWizard, terminating;

/* Init */
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[Debug setDebugLabel:debugLabel];
	
	applicationDidFinishLaunching	=	NO;
	terminateWhenDone				=	NO;
	passwordSheetIsShowing			=	NO;
	self.taskController				=	[[NSMutableArray alloc] initWithCapacity:1]; //Controller currently being extracted
	self.waitingForPasswordSheet	=	[[NSMutableArray alloc] initWithCapacity:1]; //Controller currently waiting for password sheet
	self.archiveWizard				=	[[RAUArchiveWizardController alloc] init];
	terminating						=	NO;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	applicationDidFinishLaunching = YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	if (applicationDidFinishLaunching == NO) terminateWhenDone = YES;

	NSMutableArray *archiveFiles	=	[NSMutableArray arrayWithCapacity:0];
	NSMutableArray *nonArchiveFiles	=	[NSMutableArray arrayWithCapacity:0];
	for (NSString *file in filenames) {
		if ([[file pathExtension] isEqualToString:@"rar"] == YES) 
			[archiveFiles addObject:file];
		else 
			[nonArchiveFiles addObject:file];
	}
	
	if ([archiveFiles count] == 1 && [nonArchiveFiles count] > 0) {
		[self addTaskController:[[[RAUArchiveTaskController alloc] initExistingRarfile:(NSString *)[archiveFiles objectAtIndex:0] withFilesToAdd:nonArchiveFiles] autorelease]];
	}
	else {
		for (NSString *archiveFile in archiveFiles) {
			[self addTaskController:[[[RAUExtractTaskController alloc] initWithFile:archiveFile] autorelease]];
		}
	
		if ([nonArchiveFiles count] > 0) {
			[self addTaskController:[[[RAUArchiveTaskController alloc] initNewRarfileWithFiles:nonArchiveFiles] autorelease]];
		}
	}
}

/* Add a new TaskController to the controller array and make changes to the UI */
-(void)addTaskController:(RAUTaskController *)newController {
	NSView *newView = newController.viewController.view;
	
	//The expand animation. Not done for the first file, because the window is intialized with room for one taskview
	if ([self.taskController count] != 0) [self.window expandBy:newView.frame.size.height];
	[newView setFrameOrigin:NSMakePoint(0,-1)];
	[self.windowView		addSubview:newView];	
	[self.window.introLabel	setHidden:YES]; 
	
	[[NSNotificationCenter defaultCenter] //Listen to when a Controller needs a password to extract
	 addObserver:self
	 selector:@selector(passwordSheetRequested:)
	 name:TaskControllerNeedsPasswordNotification
	 object:newController];
	[[NSNotificationCenter defaultCenter] //Listen to when a Controller finished, which means a task was completly handled
	 addObserver:self
	 selector:@selector(taskControllerDidFinish:)
	 name:TaskControllerDidFinishNotification
	 object:newController];
	
	[self.taskController addObject:newController];
	
	//[newController release];
}

/* Automatically called when a TaskController told this class it needs a password to extract the file */
-(void)passwordSheetRequested:(NSNotification *)notification {
	RAUExtractTaskController *protectedController = (RAUExtractTaskController *)[notification object];
	
	if (passwordSheetIsShowing == NO)	[self showPasswordSheet:protectedController];
	else								[self.waitingForPasswordSheet addObject:protectedController];
}

/* Shows the password sheet for a TaskController */
-(void)showPasswordSheet:(RAUExtractTaskController *)protectedController {
	[self.passwordSheetHeading 
	 setStringValue:[NSString stringWithFormat:NSLocalizedString(@"\"%@.%@\" needs a password", nil), protectedController.file.name, protectedController.file.extension]];
	
	[NSApp beginSheet: passwordSheet
	   modalForWindow: window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	self.passwordSheetController	= protectedController;
	passwordSheetIsShowing			= YES;
}

/* The OK button on the password sheet was pressed */
-(IBAction)passwordSheetPressedOK:(id)sender {
	[self.passwordSheetController	checkPassword:[self.passwordInput stringValue]];
	[self							dismissPasswordSheet];
}

/* The Cancel button on the password sheet was pressed */
-(IBAction)passwordSheetPressedCancel:(id)sender {
	[self dismissPasswordSheet];
	[self.passwordSheetController terminateTask];	
}

/* Dismiss the current password sheet. If there are TaskControler's waiting for the current password sheet to end, show new sheet */
-(void)dismissPasswordSheet {
	[NSApp endSheet:passwordSheet];
	[passwordSheet orderOut:self];
	
	[self.passwordInput setStringValue:@""];
	passwordSheetIsShowing = NO;
	
	//Check if there are any Controllers waiting for a password. If so, show a new sheet for the first one of them
	if ([self.waitingForPasswordSheet count] > 0) {
		RAUExtractTaskController *protectedController = (RAUExtractTaskController *)[self.waitingForPasswordSheet objectAtIndex:0];
		[self passwordSheetRequested:[NSNotification notificationWithName:@"NeedPwdSheet" object:protectedController]];
		[self.waitingForPasswordSheet removeObject:protectedController];
	}
}

/* Automatically called when a TaskController finishes (successfully or not, we don't care) */
-(void)taskControllerDidFinish:(NSNotification *)notification {
	RAUTaskController *finishedController = (RAUTaskController *)[notification object];
	
	if ([self.taskController containsObject:finishedController]) { //To prevent double-cancelling (double-clicking X for example)
		NSRect finishedFrame = finishedController.viewController.view.frame;
		
		/* UI: The finished taskview will be removed and leave a space. We need to move every taskview below the removed one up
		   We don't want any UI changes if we are cancelling all tasks because we want to terminate - it'd be just a waste of time */
		if (terminating == NO) {
			for (RAUTaskController *anotherController in self.taskController) {
				NSPoint anotherOrigin = anotherController.viewController.view.frame.origin; 
				if (anotherOrigin.y < finishedFrame.origin.y) {
					[anotherController.viewController.view setFrameOrigin:NSMakePoint(anotherOrigin.x, 
																					  anotherOrigin.y + finishedFrame.size.height)];
				}
			}
			
			[finishedController.viewController.view removeFromSuperview];
			if ([self.taskController count] != 1) [self.window collapseBy:finishedFrame.size.height]; 
		}
		
		[self.taskController removeObject:finishedController];
		
		if ([self.taskController count] == 0 && (terminating == YES || (terminateWhenDone == YES && self.archiveWizard.isShown == NO))) 
			[NSApp terminate:nil]; //If there are no controllers left: Terminate the entire App!
		if ([self.taskController count] == 0 && terminating == NO) 
			[self.window.introLabel	setHidden:NO]; 
	}
}

-(IBAction)showArchiveWizard:(id)sender {
	//MenuItem can be determined through tag. 0 = Complete, 1 = Create, 2 = Add
	int senderTag = [sender tag];
	if (senderTag == 0) [self.archiveWizard showCompleteWizard];
	if (senderTag == 1) [self.archiveWizard showCreateWizard];
	if (senderTag == 2) [self.archiveWizard showAddWizard];
}

-(void)archiveWizardDidClose:(BOOL)successfully {
	if (successfully == YES) terminateWhenDone = NO;
	else if ([self.taskController count] == 0 && terminateWhenDone == YES) [NSApp terminate:nil];
}

/* Called when the app delegate gets the terminate signal (either from terminate: or by pressing cmd+q) */
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([self.taskController count] == 0) return NSTerminateNow; //If we don't have any tasks left there is no more work - terminate now!
	/*If there are tasks still going on, they shouldn't leave mess behind. Stop them and tell the OS we will terminate later
	  When the last task stopped, controllerDidFinish: will automatically call [NSApp terminate] again which will cause termination */
	else {
		terminating = YES;
		for (RAUTaskController *runningController in self.taskController) {
			[runningController terminateTask];
		}
		return NSTerminateCancel; //Cancel for now - when all extractions are stopped, this method is invoked again
	}

}


-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[taskController release];
	
	[super dealloc];
}

@end
