//
//  RAUArchiveWizardController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RAUArchiveWizardController.h"
#import "RAUArchiveTaskController.h"
#import "RAR_Archive_UtilityAppDelegate.h"
#import "RAUDraggableView.h"
#import "Debug.h"


@implementation RAUArchiveWizardController
@synthesize firstPage, currentPage, isShown, finishedSuccessfully;
@synthesize mode, file, compressionLevel, shouldBeProtected, passwordNeverEntered, passwordRepetitionNeverEntered, password, passwordRepetition, shouldBeSplitted, pieceSizeNeverEntered, pieceSize, pieceSizeUnit, filesToArchive;
@synthesize pageTitleLabel, contentViewWrapper, contentView, previousPageButton, nextPageButton;
@synthesize compressionLevelWarningImage, compressionLevelWarningLabel, passwordRepetitionWarningImage, passwordRepetitionWarningLabel, passwordWarningImage, passwordWarningLabel, splitCheckbox, filesToArchiveLabel;

/**********
 * WIZARD *
 **********/

-(id)init {
	return [super initWithWindowNibName:@"ArchiveWizardWindow"];
}

/* Show the wizard starting with Page 1 */
-(void)showCompleteWizard {
	mode = ArchiveTaskModeCreate; //Initializes the UI
	[self showWindowWithPage:1];
}

/* Show the wizard starting with Page 2 and mode set to Create */
-(void)showCreateWizard {
	mode = ArchiveTaskModeCreate;
	[self showWindowWithPage:2];
	[self userWantsToChoseFile:self]; //Show the "New file"-Dialog
}

/* Show the wizard starting with Page 3 and mode set to Add */
-(void)showAddWizard {
	mode = ArchiveTaskModeAdd;
	[self showWindowWithPage:2];
	[self userWantsToChoseFile:self]; //Show the "Chose file"-Dialog
}

/* Shows the wizard (if not shown already) starting at the given page */
-(void)showWindowWithPage:(int)startingPage {
	if (isShown == NO) { //Allow only one instance of the window
		firstPage						= startingPage;
		isShown							= YES;
		finishedSuccessfully			= NO;
		
		//By setting these variables we also initialize the UI binded to that variables
		self.file						= nil;
		compressionLevel				= 3;
		shouldBeProtected				= NO;
		passwordNeverEntered			= YES;
		passwordRepetitionNeverEntered	= YES;
		self.password					= nil;
		self.passwordRepetition			= nil;
		shouldBeSplitted				= NO;
		pieceSizeNeverEntered			= YES;
		pieceSize						= 0;
		pieceSizeUnit					= 1;
		filesToArchive					= nil;
		
		[self.window setDelegate:self]; //So we can capture message regarding the window
		
		//Position and display the wizard window
		NSSize screenSize = [[self.window screen] frame].size;
		NSSize windowSize = self.window.frame.size;
		float xPos = (screenSize.width-windowSize.width)/2;
		float yPos = (screenSize.height-windowSize.height)/1.35; //Position above center
		[self.window setFrameOrigin:NSMakePoint(xPos,yPos)];
		[super showWindow:self];
		[self.window makeKeyWindow];
		
		[self loadPage:firstPage];
	}
}


/* Unloads the current page and loads a new one */
-(void)loadPage:(int)pageNumber {
	[self unloadCurrentPage];
	
	//Display the new content view. loadNibNamed loads the new page's view into contentView
	NSString *nibToLoad = [NSString stringWithFormat:@"Page%d",pageNumber];
	[NSBundle loadNibNamed:nibToLoad owner:self]; //Loads the nib's view into contentView
	[self.contentViewWrapper addSubview:self.contentView];
	currentPage = pageNumber;
	
	//Initialize the UI of the page we just loaded
	NSString *pageTitle;
	switch (currentPage) {
		case 1: //Mode-Page
			pageTitle = NSLocalizedString(@"Select a mode", nil);
			break;
		case 2: //File-Page
			if (mode == ArchiveTaskModeCreate)	pageTitle = NSLocalizedString(@"Select where to create the new RAR-File", nil);
			if (mode == ArchiveTaskModeAdd)		pageTitle = NSLocalizedString(@"Select which RAR-File to change", nil);
			break;
		case 3: //Options-Page
			pageTitle = NSLocalizedString(@"Select additional options", nil);
			[self userChoseCompressionLevel:self]; //Display compression warning if necessary
			[self displayOrHidePasswordWarnings]; //Display password warning if necessary
			if (mode == ArchiveTaskModeAdd) [self.splitCheckbox setHidden:YES];
			break;
		case 4: //Files-to-archive-Page
			pageTitle = NSLocalizedString(@"Select the files you want to archive", nil);
			[self.filesToArchiveLabel setStringValue:NSLocalizedString(@"Drag the files to be archived in here", nil)];
			[[NSNotificationCenter defaultCenter] //Listen to when files are dragged onto the view
			 addObserver:self
			 selector:@selector(userAddedFilesToArchive:)
			 name:FilesDraggedNotification
			 object:self.contentView];
			break;
	}
	[self.pageTitleLabel setStringValue:pageTitle];
	[self updateNavigationButtons];
}

/* Removes the current page from the content view */
-(void)unloadCurrentPage {
	if (self.contentView != nil) [self.contentView removeFromSuperview];
	self.contentView = nil;
}

/* Checks if the current page is ready to proceed to the next page */
-(BOOL)currentPageReady {
	switch (currentPage) {
		case 1: //Mode - always ready
			return YES;
			break;
		case 2: //File - when a file was entered, page is ready
			return ([self.file length] > 0);
			break;
		case 3: //Options - If password wished, passwort must have been entered twice. If split wished, split value must have been entered
			if (shouldBeProtected == YES && ([self isPasswordCorrect] == NO || [self IsPasswordRepetitionCorrect] == NO))
				return NO;
			if (shouldBeSplitted == YES && [self pieceSizeCorrect] == NO) 
				return NO;
			return YES;
			break;
		case 4: //Files to archive - ready as soon as at least one file was dragged into the view
			return ([self.filesToArchive count] > 0);
			break;
	}
	return NO; //Just in case
}

/* User clicked the "Go Back"-Button */
-(IBAction)previousPageButtonClicked:(id)sender {
	if ([self.previousPageButton isEnabled] == YES) {
		[self.previousPageButton setEnabled:NO]; //To prevent quickly clicking the button numerous times
		if (currentPage > firstPage)
			[self loadPage:(currentPage-1)];
	}
}

/* User clicked the "Continue/Finish"-Button */
-(IBAction)nextPageButtonClicked:(id)sender {
	if ([self.nextPageButton isEnabled] == YES) {
		if (currentPage >= LASTPAGE) { //Last page - Finish the wizard
			//Prepare Data
			if (shouldBeProtected == NO) self.password = nil;
			if (shouldBeSplitted == NO) pieceSize = 0;
			 
			//Create the TaskController with all data the user entered
			RAUArchiveTaskController *archiveController;
			if (mode == ArchiveTaskModeCreate) {
				if (shouldBeSplitted == NO)	
					archiveController = [[RAUArchiveTaskController alloc] initNewRarfile:self.file withFiles:self.filesToArchive password:self.password compressionLevel:compressionLevel];
				else {
					if (pieceSizeUnit == 1) pieceSize *= 1000;
					if (pieceSizeUnit == 2) pieceSize *= 1000000;
					archiveController = [[RAUArchiveTaskController alloc] initNewRarfile:self.file withFiles:self.filesToArchive password:self.password compressionLevel:compressionLevel pieceSize:pieceSize];
				}
			} 
			 
			if (mode == ArchiveTaskModeAdd) {
				archiveController = [[RAUArchiveTaskController alloc] initExistingRarfile:self.file withFilesToAdd:self.filesToArchive password:self.password compressionLevel:compressionLevel];
			}
			 
			RAR_Archive_UtilityAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
			[appDelegate addTaskController:archiveController];
			[archiveController autorelease];
			
			finishedSuccessfully = YES;
			[self close];
		}
		else if ([self currentPageReady] == YES) {
			[self.nextPageButton setEnabled:NO]; //To prevent quickly clicking the button numerous times
			[self loadPage:(currentPage+1)];
		}
	}
}

/* Needed so the user can navigate the wizard with enter/backspace keys */
-(void)keyDown:(NSEvent *)event {
	NSString *pressedKeys = [event charactersIgnoringModifiers];
	if ([pressedKeys length] > 0) {
		unichar lastCharPressed = [pressedKeys characterAtIndex:[pressedKeys length]-1];
		if (lastCharPressed == NSEnterCharacter || lastCharPressed == NSCarriageReturnCharacter) [self nextPageButtonClicked:self];
		if (lastCharPressed == NSDeleteCharacter) [self previousPageButtonClicked:self];
	}
}

/* User clicked the "Quit"-Button */
-(IBAction)closeWindow:(id)sender {
	[self close];
}

-(void)updateNavigationButtons {
	//Go-Back-Button
	if (currentPage == firstPage)	[self.previousPageButton setEnabled:NO];
	else							[self.previousPageButton setEnabled:YES];
	
	//Contine-Button
	if ([self currentPageReady] == NO)	[self.nextPageButton setEnabled:NO];
	else								[self.nextPageButton setEnabled:YES];
	
	if (currentPage == LASTPAGE)	[self.nextPageButton setTitle:NSLocalizedString(@"Finish", nil)]; 
	else							[self.nextPageButton setTitle:NSLocalizedString(@"Continue", nil)];
	
}

/* Wizard-window is closed by any means (it finished, X clicked, quit button clicked, ...) */
-(void)windowWillClose:(NSNotification *)notification {
	[self unloadCurrentPage];
	isShown = NO;
}

/* Called by the NSWindow when it should be closed */
-(void)close {
	[super close];
	
	RAR_Archive_UtilityAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[appDelegate archiveWizardDidClose:finishedSuccessfully];
}

/**********
 * PAGE 1 *
 **********/

/* User selected a new mode from the radio buttons */
-(IBAction)userChoseMode:(id)sender {
	//When the mode changes, clear the file (page 2), because we change between existing and new rarfiles
	self.file = nil;
	
	[self updateNavigationButtons];
}

/**********
 * PAGE 2 *
 **********/

/* User wants to select a file */
-(IBAction)userWantsToChoseFile:(id)sender {
	if (mode == ArchiveTaskModeAdd) { //Show an openPanel to open an existing rarfile
		NSOpenPanel* fileDialog = [NSOpenPanel openPanel];
		[fileDialog setCanChooseFiles:YES];
		[fileDialog setCanChooseDirectories:NO];
	
		int result = [fileDialog runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] file:nil types:[NSArray arrayWithObject:@"rar"]];
		if (result == NSOKButton)
			self.file = [[fileDialog filenames] objectAtIndex:0]; //We don't allow multiple file selection, so always take index 0
	}
	
	if (mode == ArchiveTaskModeCreate) { //Show a savePanel to chose the location of a completly new rarfile
		NSSavePanel *fileDialog = [NSSavePanel savePanel];
		[fileDialog setRequiredFileType:@"rar"];
		
		int result = [fileDialog runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] file:nil];
		if (result == NSOKButton) 
			self.file = [fileDialog filename]; 
	}
	
	[self updateNavigationButtons];
}

/**********
 * PAGE 3 *
 **********/

/* User chose a compression level */
-(IBAction)userChoseCompressionLevel:(id)sender {
	[self displayOrHideCompressionWarning];
	[self updateNavigationButtons];
}

/* Displays or hides the compression warning based on the currently chosen compression */
-(void)displayOrHideCompressionWarning {
	//When the user selects "Store only" or "Very strong compression" display a warning
	if (compressionLevel == 0) [self.compressionLevelWarningLabel setStringValue:NSLocalizedString(@"Your files will not be compressed", nil)];
	if (compressionLevel == 5) [self.compressionLevelWarningLabel setStringValue:NSLocalizedString(@"This might take a very long time", nil)];
	
	BOOL showWarning = (compressionLevel == 0 || compressionLevel == 5);
	[self.compressionLevelWarningImage setHidden:!showWarning];
	[self.compressionLevelWarningLabel setHidden:!showWarning];
}

/* User checked or unchecked the passwort checkbox */
-(IBAction)userToggledPassword:(id)sender {
	//Changing the checkboxes state maybe means the continue button gets enabled/disabled
	[self updateNavigationButtons]; 
}

/* Returns if the password field is correct */
-(BOOL)isPasswordCorrect {
	return ([self.password length] > 0);
}

/* Returns if the passwort repetition is correct */
-(BOOL)IsPasswordRepetitionCorrect {
	return ([self.password isEqualToString:self.passwordRepetition] == YES);
}

/* Display or hides the warnings regarding the password */
-(void)displayOrHidePasswordWarnings {
	//Show "Please enter password" when nothing was entered
	BOOL showPasswordWarning = ([self isPasswordCorrect] == NO && passwordNeverEntered == NO);
	//Show "Not identical" when a password was entered but the repetition is not the same
	BOOL showRepetitionWarning = ([self isPasswordCorrect] == YES && [self IsPasswordRepetitionCorrect] == NO && passwordRepetitionNeverEntered == NO);
	BOOL showWarning = (showPasswordWarning == YES || showRepetitionWarning == YES);
	
	if (showPasswordWarning == YES) [self.passwordWarningLabel setStringValue:NSLocalizedString(@"Please enter a password", nil)];
	else if (showRepetitionWarning == YES) [self.passwordWarningLabel setStringValue:NSLocalizedString(@"Passwords not identical", nil)];
	[self.passwordWarningImage setHidden:!showWarning];
	[self.passwordWarningLabel setHidden:!showWarning];
}

/* Called every time the user changes a character in the password field (due to Bindings) */
-(void)setPassword:(NSString *)value {
	if ([value length] > 0) passwordNeverEntered = NO;
	[password autorelease];
	password = [value copy];
	
	[self displayOrHidePasswordWarnings];
	[self updateNavigationButtons];
}

/* Called every time the user changes a character in the repetition field (due to Bindings) */
-(void)setPasswordRepetition:(NSString *)value {
	if (value > 0) passwordRepetitionNeverEntered = NO;
	[passwordRepetition autorelease];
	passwordRepetition = [value copy];
	
	[self displayOrHidePasswordWarnings];
	[self updateNavigationButtons];
}

/* User checked or unchecked the splitting checkbox */
-(IBAction)userToggledSplitting:(id)sender {
	//Changing the checkboxes state maybe means the continue button gets enabled/disabled
	[self updateNavigationButtons];
}

/* Returns if the user entered a valid piece size */
-(BOOL)pieceSizeCorrect {
	return (pieceSize > 0);
}

/* Called every time the user changes a character in the piece-size field (due to Bindings) */
-(void)setPieceSize:(float)value {
	pieceSizeNeverEntered = NO;
	pieceSize = value;
	
	[self updateNavigationButtons];
}

/**********
 * PAGE 4 *
 **********/

/* User dragged new files into the view */
-(void)userAddedFilesToArchive:(NSNotification *)notification {
	//The set to nil is needed so the binding notices a change (otherwise the value of filesToArchive wouldn't change as it is a reference)
	self.filesToArchive = nil; 
	self.filesToArchive = [[notification object] draggedFiles]; //RAUDraggableView keeps a list of all tracked files
	
	[self updateNavigationButtons];
}

@end
