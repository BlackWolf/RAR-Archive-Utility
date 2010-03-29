//
//  RAUArchiveWizardController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Represents the archive wizard window. Takes care of getting an validating all the data from the user, creating the
// RAUTaskController based on the user data and of course everything regarding the wizards UI

#import "RAUArchiveWizardController.h"
#import "RAUArchiveTaskController.h"
#import "RAR_Archive_UtilityAppDelegate.h"
#import "RAUDraggableView.h"


@implementation RAUArchiveWizardController

#pragma mark -
@synthesize firstPage, currentPage, isShown, finishedSuccessfully;
@synthesize pageTitleLabel, contentViewWrapper, contentView, previousPageButton, nextPageButton;

-(id)init {
	return [super initWithWindowNibName:@"ArchiveWizardWindow"];
}

-(void)showCompleteWizard {
	mode = ArchiveTaskModeCreate; //Initializes the UI
	[self showWindowWithPage:1];
}

-(void)showCreateWizard {
	mode = ArchiveTaskModeCreate;
	[self showWindowWithPage:2];
	[self userWantsToChoseFile:self]; //Show the "New file"-Dialog
}

-(void)showAddWizard {
	mode = ArchiveTaskModeAdd;
	[self showWindowWithPage:2];
	[self userWantsToChoseFile:self]; //Show the "Chose file"-Dialog
}

/* Shows the wizard starting at the given page */
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

/* Wizard-window is closed by any means (it finished, X clicked, quit button clicked, ...) */
-(void)windowWillClose:(NSNotification *)notification {
	[self unloadCurrentPage];
	
	RAR_Archive_UtilityAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[appDelegate archiveWizardDidClose:finishedSuccessfully];
	
	isShown = NO;
}

#pragma mark -
#pragma mark Navigating through pages

-(IBAction)previousPageButtonClicked:(id)sender {
	if ([self.previousPageButton isEnabled] == YES) {
		[self.previousPageButton setEnabled:NO]; 
		if (currentPage > firstPage)
			[self loadPage:(currentPage-1)];
	}
}

-(IBAction)nextPageButtonClicked:(id)sender {
	if ([self.nextPageButton isEnabled] == YES) {
		[self.nextPageButton setEnabled:NO]; 
		
		if (currentPage >= LASTPAGE) { //Last page - Finish the wizard
			//Prepare Data
			if (shouldBeProtected == NO) self.password = nil;
			if (shouldBeSplitted == NO)	pieceSize = 0;
			
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
		else if ([self currentPageReady] == YES) { //not the last page and current page is ready to proceed
			[self loadPage:(currentPage+1)];
		}
	}
}

-(IBAction)quitButtonClicked:(id)sender {
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

/* Needed so the user can navigate the wizard with enter/backspace keys */
-(void)keyDown:(NSEvent *)event {
	NSString *pressedKeys = [event charactersIgnoringModifiers];
	if ([pressedKeys length] > 0) {
		unichar lastCharPressed = [pressedKeys characterAtIndex:[pressedKeys length]-1];
		if (lastCharPressed == NSEnterCharacter || lastCharPressed == NSCarriageReturnCharacter) [self nextPageButtonClicked:self];
		if (lastCharPressed == NSDeleteCharacter) [self previousPageButtonClicked:self];
	}
}

#pragma mark -
#pragma mark All Pages

/* Loads the page pageNumber into the wizard window */
-(void)loadPage:(int)pageNumber {
	[self unloadCurrentPage];
	
	//Display the new content view. loadNibNamed loads the new pages view into contentView
	NSString *nibToLoad = [NSString stringWithFormat:@"Page%d",pageNumber];
	[NSBundle					loadNibNamed:nibToLoad owner:self]; 
	[self.contentViewWrapper	addSubview:self.contentView];
	
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
			
			//Listen to when files are dragged onto the view
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(userAddedFilesToArchive:)
														 name:FilesDraggedNotification
													   object:self.contentView];
			break;
	}
	[self.pageTitleLabel setStringValue:pageTitle];
	[self updateNavigationButtons];
}

/* Remove the currently loaded page from the wizard window */
-(void)unloadCurrentPage {
	if (self.contentView != nil) [self.contentView removeFromSuperview];
	self.contentView = nil;
}

/* Returns a boolean value determining if the current page is ready to proceed to the next page */
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

#pragma mark -
#pragma mark Page 1 (Mode)
@synthesize mode;

-(IBAction)userChoseMode:(id)sender {
	//When the mode changes, clear the file (page 2), because we change between existing and new rarfiles
	self.file = nil;
	
	[self updateNavigationButtons];
}

#pragma mark -
#pragma mark Page 2 (File)
@synthesize file;

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

#pragma mark -
#pragma mark Page 3 (Options)
@synthesize compressionLevel;
@synthesize shouldBeProtected, passwordNeverEntered, passwordRepetitionNeverEntered, password, passwordRepetition;
@synthesize shouldBeSplitted, pieceSizeNeverEntered, pieceSize, pieceSizeUnit;
@synthesize compressionLevelWarningImage, compressionLevelWarningLabel;
@synthesize passwordRepetitionWarningImage, passwordRepetitionWarningLabel, passwordWarningImage, passwordWarningLabel;
@synthesize splitCheckbox;

-(IBAction)userChoseCompressionLevel:(id)sender {
	[self displayOrHideCompressionWarning];
	[self updateNavigationButtons];
}

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
	[self updateNavigationButtons]; 
}

-(BOOL)isPasswordCorrect {
	return ([self.password length] > 0);
}

-(BOOL)IsPasswordRepetitionCorrect {
	return ([self.password isEqualToString:self.passwordRepetition] == YES);
}

-(void)displayOrHidePasswordWarnings {
	//Show warning if nothing was entered. If the user never TRIED to enter something, do not show a warning
	BOOL showPasswordWarning = ([self isPasswordCorrect] == NO && passwordNeverEntered == NO);
	//Show warning if password and repetition are not identical. Don't if user didn't even try to enter yet
	BOOL showRepetitionWarning = ([self isPasswordCorrect] == YES && [self IsPasswordRepetitionCorrect] == NO && passwordRepetitionNeverEntered == NO);
	BOOL showWarning = (showPasswordWarning == YES || showRepetitionWarning == YES);
	
	//Don't show both warnings and give priority to the "no password" warning
	if (showPasswordWarning == YES) [self.passwordWarningLabel setStringValue:NSLocalizedString(@"Please enter a password", nil)];
	else if (showRepetitionWarning == YES) [self.passwordWarningLabel setStringValue:NSLocalizedString(@"Passwords not identical", nil)];
	
	[self.passwordWarningImage setHidden:!showWarning];
	[self.passwordWarningLabel setHidden:!showWarning];
}

/* Automatically called every time the user changes a character in the password field */
-(void)setPassword:(NSString *)value {
	[password autorelease];
	password = [value copy];
	
	if ([value length] > 0) passwordNeverEntered = NO;
	[self displayOrHidePasswordWarnings];
	[self updateNavigationButtons];
}

/* Automatically called every time the user changes a character in the repetition field */
-(void)setPasswordRepetition:(NSString *)value {
	[passwordRepetition autorelease];
	passwordRepetition = [value copy];
	
	if (value > 0) passwordRepetitionNeverEntered = NO;
	[self displayOrHidePasswordWarnings];
	[self updateNavigationButtons];
}

/* User checked or unchecked the splitting checkbox */
-(IBAction)userToggledSplitting:(id)sender {
	[self updateNavigationButtons];
}

-(BOOL)pieceSizeCorrect {
	return (pieceSize > 0);
}

/* Automatically called every time the user changes a character in the piece-size field */
-(void)setPieceSize:(float)value {
	pieceSize = value;
	
	pieceSizeNeverEntered = NO;
	[self updateNavigationButtons];
}

#pragma mark -
#pragma mark Page 4 (Files to archive)
@synthesize filesToArchive;
@synthesize filesToArchiveLabel;

-(void)userAddedFilesToArchive:(NSNotification *)notification {
	//Since filesToArchive is a reference, we need to set it to nil first so that the cocoa bindings notice a change in its value
	self.filesToArchive = nil; 
	self.filesToArchive = [[notification object] draggedFiles]; //RAUDraggableView keeps a list of all tracked files
	
	[self updateNavigationButtons];
}

@end
