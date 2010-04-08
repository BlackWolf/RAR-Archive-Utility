//
//  RAR_Archive_UtilityAppDelegate.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Main application file. Receives a message when the user wants to open one or more files. It keeps track of all currently running rar
// tasks (RAUTaskControllers) and their views on the main window. its also responsible for asking the user for a password if one of the
// taskcontroller asks for one
//

#import "RAR_Archive_UtilityAppDelegate.h"
#import "RAURarfile.h"
#import "RAUMainWindow.h"
#import "RAUExtractTaskController.h"
#import "RAUCreateTaskController.h"
#import "RAUAddTaskController.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"
#import "RAUArchiveWizardController.h"
#import "RAUTaskViewController.h"


@implementation RAR_Archive_UtilityAppDelegate

#pragma mark -
@synthesize window, windowView;
@synthesize applicationDidFinishLaunching, terminateWhenDone, terminating;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
	applicationDidFinishLaunching	= NO; 
	terminateWhenDone				= NO; 
	passwordSheetIsShowing			= NO;
	taskController					= [[NSMutableArray alloc] initWithCapacity:1]; //List of all current taskController
	waitingPasswordSheetTasks		= [[NSMutableArray alloc] initWithCapacity:1]; //Controller currently waiting for password sheet
	archiveWizard					= [[RAUArchiveWizardController alloc] init];
	terminating						= NO;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	applicationDidFinishLaunching = YES;
}

/* Called when the user wants to open one or multiple files (by double-clicking, "open with" or dragging onto the app) */
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	//If this is called before didFinishLaunching, app was opened by double-clicking a rar-file -> terminate after finishing
	if (applicationDidFinishLaunching == NO) terminateWhenDone = YES;

	NSMutableArray *archiveFiles	=	[NSMutableArray arrayWithCapacity:0];
	NSMutableArray *nonArchiveFiles	=	[NSMutableArray arrayWithCapacity:0];
	for (NSString *file in filenames) {
		if ([[file pathExtension] isEqualToString:@"rar"] == YES) 
			[archiveFiles addObject:file];
		else 
			[nonArchiveFiles addObject:file];
	}
	
	//One Archive and other files? Add the files to the archive
	if ([archiveFiles count] == 1 && [nonArchiveFiles count] > 0) {
		RAUPath *archiveFilePath = [RAUPath pathWithFile:[archiveFiles objectAtIndex:0]];
		RAUAddTaskController *newController = [[RAUAddTaskController alloc] initWithFilesToArchive:nonArchiveFiles inRarfile:archiveFilePath];
		[self addTaskController:newController];
		[newController release];
	}
	else {
		for (NSString *archiveFile in archiveFiles) {
			RAUPath *archiveFilePath = [RAUPath pathWithFile:archiveFile];
			RAUExtractTaskController *newController = [[RAUExtractTaskController alloc] initWithFilePath:archiveFilePath];
			[self addTaskController:newController];
			[newController release];
		}
	
		if ([nonArchiveFiles count] > 0) {
			RAUCreateTaskController *newController = [[RAUCreateTaskController alloc] initWithFilesToArchive:nonArchiveFiles];
			[self addTaskController:newController];
			[newController release];
		}
	}
}

/* Called when the app delegate gets the terminate signal (either from terminate: or by pressing cmd+q) */
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([taskController count] == 0) return NSTerminateNow; 
	
	/* If there are tasks still going on, they shouldn't leave mess behind. Stop them and tell the OS we will terminate later
	 When the last task stopped, controllerDidFinish: will automatically call [NSApp terminate] again which will cause termination */
	else {
		terminating = YES; 
		for (RAUTaskController *runningController in taskController) {
			[runningController terminateTask];
		}
		return NSTerminateCancel;
	}
	
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[taskController				release]; //alloced in init
	[passwordSheet				release]; //top-level IB-Object
	[currentPasswordSheetTask	release]; //retained in showPasswordSheet
	[waitingPasswordSheetTasks	release]; //alloced in init
	[archiveWizard				release]; //alloced in showArchiveWizard
	
	
	[super dealloc];
}

#pragma mark -
#pragma mark RAUTaskControllerDelegate methods
@synthesize taskController;

/* Called when a new rartask (in form of a RAUTaskController) was started and should be tracked by this class */
-(void)addTaskController:(RAUTaskController *)newController {
	[newController setDelegate:self];
	
	NSView *newView = newController.viewController.view;
	
	//The expand animation. Not done for the first task, because the window is intialized with room for one taskview
	if ([taskController count] != 0) [window expandBy:newView.frame.size.height];
	
	[newView			setFrameOrigin:NSMakePoint(0,-1)]; //A cosmetic thing to hide the black line on the bottom of the view
	[windowView			addSubview:newView];	
	[window.introLabel	setHidden:YES]; 
	
	[taskController addObject:newController];
}

/* RAUTaskControllerDelegate method: Called when the task controller detected its rarfile is invalid and it cannot proceed */
-(void)taskControllerRarfileInvalid:(RAUTaskController *)invalidController {
	NSString *filenameToDisplay = [NSString stringWithFormat:@"%@.%@", invalidController.rarfile.path.filename, invalidController.rarfile.path.extension];
	
	//Show an alert informing the user of the invalid rarfile, then kill the task controller
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setIcon:[NSImage imageNamed:@"caution.png"]];
	[alert setMessageText:@"Invalid RAR-File?"];
	[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" seems to be no RAR-File or of an unknown format.\nIf the file is supposed to be valid, try again.\n\nIf this error occurs again and you are sure your file is valid, please contact the developer.", nil),
							   filenameToDisplay]];
	[alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[alert release];
	
	[self taskControllerDidFinish:invalidController];
}

/* RAUTaskControllerDelegate method: Called as soon as a task controllers task is ready to be launched */
-(void)taskControllerIsReady:(RAUTaskController *)readyController {
	[readyController launchTask];
}

/* RAUTaskControllerDelegate method: Called when a TaskController finishes (successfully or not, we don't care) */
-(void)taskControllerDidFinish:(RAUTaskController *)finishedController {
	if ([taskController containsObject:finishedController]) { //To prevent double-cancelling (double-clicking X for example)
		NSRect finishedFrame = finishedController.viewController.view.frame;
		
		/* UI: The finished taskview will be removed and leave a space. We need to move every taskview below the removed one up
		 We don't want any UI changes if we are terminating - it'd be just a waste of time */
		if (terminating == NO) {
			for (RAUTaskController *anotherController in taskController) {
				NSPoint anotherOrigin = anotherController.viewController.view.frame.origin; 
				if (anotherOrigin.y < finishedFrame.origin.y) { //anotherController is below finishedController
					[anotherController.viewController.view setFrameOrigin:NSMakePoint(anotherOrigin.x, 
																					  anotherOrigin.y + finishedFrame.size.height)];
				}
			}
			
			[finishedController.viewController.view removeFromSuperview];
			
			//Collapse animation - not done for the last controller, as we always want a window the size of one taskController
			if ([taskController count] != 1) [window collapseBy:finishedFrame.size.height]; 
		}
		
		[taskController removeObject:finishedController];
		
		//No controller left and terminating is YES (which means the user pressed CMD+Q or something)
		if ([taskController count] == 0 && terminating == YES) {
			[NSApp terminate:nil];
		//We are done and terminateWhenDone is YES: - terminate. Exception: The wizard is currently shown (so the user is working)
		} else if ([taskController count] == 0 && terminateWhenDone == YES && archiveWizard.isShown == NO) {
			[NSApp terminate:nil];
		//If there are no controllers left and we didn't terminate: Show the intro label
		} else if ([taskController count] == 0) 
			[window.introLabel setHidden:NO]; 
	}
}

/* RAUTaskControllerDelegate method: Called when a taskController needs a password for its rarfile */
-(void)taskControllerNeedsPassword:(RAUTaskController *)needyController {	
	if (passwordSheetIsShowing == NO)											[self showPasswordSheet:needyController];
	else if ([waitingPasswordSheetTasks containsObject:needyController] == NO)	[waitingPasswordSheetTasks addObject:needyController];
}

#pragma mark -
#pragma mark Password Sheets
@synthesize passwordSheet, passwordSheetHeading, passwordSheetTextField;
@synthesize passwordSheetIsShowing, currentPasswordSheetTask, waitingPasswordSheetTasks;

-(void)showPasswordSheet:(RAUTaskController *)needyController {
	[passwordSheetHeading setStringValue:[NSString stringWithFormat:NSLocalizedString(@"\"%@.%@\" needs a password", nil), 
											   needyController.rarfile.path.filename, needyController.rarfile.path.extension]];
	[passwordSheetTextField setStringValue:@""];
	
	[NSApp beginSheet:passwordSheet modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
	currentPasswordSheetTask	= [needyController retain]; //release when sheet is dismissed
	passwordSheetIsShowing		= YES;
}

-(IBAction)passwordSheetPressedOK:(id)sender {
	if ([[self.passwordSheetTextField stringValue] length] > 0) {
		[currentPasswordSheetTask	setPasswordArgument:[passwordSheetTextField stringValue]];
		[self						dismissPasswordSheet];
	}
}

-(IBAction)passwordSheetPressedCancel:(id)sender {
	[self						dismissPasswordSheet];
	[currentPasswordSheetTask	terminateTask];	
}

-(void)dismissPasswordSheet {
	[currentPasswordSheetTask release]; //retained when sheet was shown
	
	[NSApp endSheet:passwordSheet];
	[passwordSheet orderOut:self];
	
	passwordSheetIsShowing = NO;
	
	//Check if there are any Controllers waiting for a password. If so, show a new sheet for the first one of them
	if ([waitingPasswordSheetTasks count] > 0) {
		RAUTaskController *needyController = (RAUTaskController *)[waitingPasswordSheetTasks objectAtIndex:0];
		[self taskControllerNeedsPassword:needyController];
		[waitingPasswordSheetTasks removeObject:needyController];
	}
}

#pragma mark -
#pragma mark Archive Wizard
@synthesize archiveWizard;

-(IBAction)showArchiveWizard:(id)sender {	
	//MenuItem clicked can be determined through tag. 0 = Complete, 1 = Create, 2 = Add
	int senderTag = [sender tag];
	if (senderTag == 0) [self.archiveWizard showCompleteWizard];
	if (senderTag == 1) [self.archiveWizard showCreateWizard];
	if (senderTag == 2) [self.archiveWizard showAddWizard];
}

/* Automatically called by the wizard. successfully determines if a TaskController was actually created or if the user aborted */
-(void)archiveWizardDidClose:(BOOL)successfully {
	//No auto-termination if the user created a task via the wizard
	if (successfully == YES) terminateWhenDone = NO; 
	//If we didn't terminate in taskControllerDidFinish: because the wizard was still open, do so now since the user aborted it
	else if ([taskController count] == 0 && terminateWhenDone == YES) [NSApp terminate:nil];
}

@end
