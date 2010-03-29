//
//  RAR_Archive_UtilityAppDelegate.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Main application file. Receives a message when the user wants to open files. Also manages all the TaskController (each representing
// an extraction or archiving task) and their Views on the Main UI
//

#import "RAR_Archive_UtilityAppDelegate.h"
#import "RAUMainWindow.h"
#import "RAUExtractTaskController.h"
#import "RAUArchiveTaskController.h"
#import "RAUTaskViewController.h"
#import "RAURarfile.h"
#import "RAUArchiveWizardController.h"


@implementation RAR_Archive_UtilityAppDelegate

#pragma mark -
@synthesize window, windowView;
@synthesize applicationDidFinishLaunching, terminateWhenDone, terminating;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
	applicationDidFinishLaunching	=	NO; 
	terminateWhenDone				=	NO; 
	passwordSheetIsShowing			=	NO;
	self.taskController				=	[[NSMutableArray alloc] initWithCapacity:1]; //List of all current taskController
	self.waitingPasswordSheetTasks	=	[[NSMutableArray alloc] initWithCapacity:1]; //Controller currently waiting for password sheet
	self.archiveWizard				=	[[RAUArchiveWizardController alloc] init];
	terminating						=	NO;
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

/* Called when the app delegate gets the terminate signal (either from terminate: or by pressing cmd+q) */
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([self.taskController count] == 0) return NSTerminateNow; 
	
	/* If there are tasks still going on, they shouldn't leave mess behind. Stop them and tell the OS we will terminate later
	 When the last task stopped, controllerDidFinish: will automatically call [NSApp terminate] again which will cause termination */
	else {
		terminating = YES; 
		for (RAUTaskController *runningController in self.taskController) {
			[runningController terminateTask];
		}
		return NSTerminateCancel;
	}
	
}


-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[taskController				release];
	[passwordSheet				release];
	[currentPasswordSheetTask	release];
	[waitingPasswordSheetTasks	release];
	[archiveWizard				release];
	
	
	[super dealloc];
}

#pragma mark -
#pragma mark TaskController
@synthesize taskController;

/* Adds a TaskController to the Controller-Array so we can access it later. Also adds the Controllers View to the main UI */
-(void)addTaskController:(RAUTaskController *)newController {
	NSView *newView = newController.viewController.view;
	
	//The expand animation. Not done for the first task, because the window is intialized with room for one taskview
	if ([self.taskController count] != 0) [self.window expandBy:newView.frame.size.height];
	
	[newView setFrameOrigin:NSMakePoint(0,-1)]; //A cosmetic thing
	[self.windowView		addSubview:newView];	
	[self.window.introLabel	setHidden:YES]; 
	
	 //Listen to when a Controller needs a password to extract and to when a controller finishes
	[[NSNotificationCenter defaultCenter]  addObserver:self 
											  selector:@selector(passwordSheetRequested:) 
												  name:TaskControllerNeedsPasswordNotification 
												object:newController];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskControllerDidFinish:)
												 name:TaskControllerDidFinishNotification
											   object:newController];
	
	[self.taskController addObject:newController];
}

/* Automatically called when a TaskController finishes (successfully or not, we don't care) */
-(void)taskControllerDidFinish:(NSNotification *)notification {
	RAUTaskController *finishedController = (RAUTaskController *)[notification object];
	
	if ([self.taskController containsObject:finishedController]) { //To prevent double-cancelling (double-clicking X for example)
		NSRect finishedFrame = finishedController.viewController.view.frame;
		
		/* UI: The finished taskview will be removed and leave a space. We need to move every taskview below the removed one up
		 We don't want any UI changes if we are terminating - it'd be just a waste of time */
		if (terminating == NO) {
			for (RAUTaskController *anotherController in self.taskController) {
				NSPoint anotherOrigin = anotherController.viewController.view.frame.origin; 
				if (anotherOrigin.y < finishedFrame.origin.y) { //anotherController is BELOW finishedController
					[anotherController.viewController.view setFrameOrigin:NSMakePoint(anotherOrigin.x, 
																					  anotherOrigin.y + finishedFrame.size.height)];
				}
			}
			
			[finishedController.viewController.view removeFromSuperview];
			
			//Collapse animation - not done for the last controller, as we always want a window the size of one taskController
			if ([self.taskController count] != 1) [self.window collapseBy:finishedFrame.size.height]; 
		}
		
		[self.taskController removeObject:finishedController];
		
		//No controller left and terminating is YES (which means the user pressed CMD+Q or something)
		if ([self.taskController count] == 0 && terminating == YES) {
			[NSApp terminate:nil];
		//We are done and terminateWhenDone is YES: terminate. Exception: The wizard is currently shown (so the user is working)
		} else if ([self.taskController count] == 0 && terminateWhenDone == YES && self.archiveWizard.isShown == NO) {
			[NSApp terminate:nil];
		//If there are no controllers left and we didn't terminate: Show the intro label
		} else if ([self.taskController count] == 0) 
			[self.window.introLabel	setHidden:NO]; 
	}
}

#pragma mark -
#pragma mark Password Sheets
@synthesize passwordSheet, passwordSheetHeading, passwordSheetTextField;
@synthesize passwordSheetIsShowing, currentPasswordSheetTask, waitingPasswordSheetTasks;

/* Automatically called when a TaskController sends a notification that it needs a password to proceed */
-(void)passwordSheetRequested:(NSNotification *)notification {
	RAUExtractTaskController *protectedController = (RAUExtractTaskController *)[notification object];
	
	if (passwordSheetIsShowing == NO)	[self showPasswordSheet:protectedController];
	else								[self.waitingPasswordSheetTasks addObject:protectedController];
}

-(void)showPasswordSheet:(RAUExtractTaskController *)protectedController {
	[self.passwordSheetHeading setStringValue:[NSString stringWithFormat:NSLocalizedString(@"\"%@.%@\" needs a password", nil), 
											   protectedController.file.name, protectedController.file.extension]];
	
	[NSApp beginSheet:passwordSheet modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
	self.currentPasswordSheetTask	= protectedController;
	passwordSheetIsShowing			= YES;
}

-(IBAction)passwordSheetPressedOK:(id)sender {
	[self.currentPasswordSheetTask	checkPassword:[self.passwordSheetTextField stringValue]];
	[self							dismissPasswordSheet];
}

-(IBAction)passwordSheetPressedCancel:(id)sender {
	[self dismissPasswordSheet];
	[self.currentPasswordSheetTask terminateTask];	
}

-(void)dismissPasswordSheet {
	[NSApp endSheet:passwordSheet];
	[passwordSheet orderOut:self];
	
	[self.passwordSheetTextField setStringValue:@""];
	passwordSheetIsShowing = NO;
	
	//Check if there are any Controllers waiting for a password. If so, show a new sheet for the first one of them
	if ([self.waitingPasswordSheetTasks count] > 0) {
		RAUExtractTaskController *protectedController = (RAUExtractTaskController *)[self.waitingPasswordSheetTasks objectAtIndex:0];
		[self passwordSheetRequested:[NSNotification notificationWithName:@"NeedPwdSheet" object:protectedController]];
		[self.waitingPasswordSheetTasks removeObject:protectedController];
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
	else if ([self.taskController count] == 0 && terminateWhenDone == YES) [NSApp terminate:nil];
}

@end
