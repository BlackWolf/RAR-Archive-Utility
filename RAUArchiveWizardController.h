//
//  RAUArchiveWizardController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUArchiveTask.h"


#define LASTPAGE 4

@interface RAUArchiveWizardController : NSWindowController <NSWindowDelegate> {
	//Global
	int				firstPage;
	int				currentPage;
	BOOL			isShown;
	BOOL			finishedSuccessfully;
	
	//Global UI
	NSTextField		*pageTitleLabel;
	NSView			*contentViewWrapper;
	NSView			*contentView;
	NSButton		*previousPageButton;
	NSButton		*nextPageButton;
	
	//Page-specific
	
	ArchiveTaskMode	mode;
	NSString		*file;
	int				compressionLevel;
	BOOL			shouldBeProtected;
	BOOL			passwordNeverEntered;
	BOOL			passwordRepetitionNeverEntered;
	NSString		*password;
	NSString		*passwordRepetition;
	BOOL			shouldBeSplitted;
	BOOL			pieceSizeNeverEntered;
	float			pieceSize;
	int				pieceSizeUnit;
	NSMutableArray	*filesToArchive;
	
	//Page-specific UI
	NSImageView		*compressionLevelWarningImage;
	NSTextField		*compressionLevelWarningLabel;
	NSImageView		*passwordRepetitionWarningImage;
	NSTextField		*passwordRepetitionWarningLabel;
	NSImageView		*passwordWarningImage;
	NSTextField		*passwordWarningLabel;
	NSButton		*splitCheckbox;
	NSTextField		*filesToArchiveLabel;
}

@property (assign)				int				firstPage;
@property (assign)				int				currentPage;
@property (assign)				BOOL			isShown;
@property (assign)				BOOL			finishedSuccessfully;

@property (assign)	IBOutlet	NSTextField		*pageTitleLabel;
@property (assign)	IBOutlet	NSView			*contentViewWrapper;
@property (assign)	IBOutlet	NSView			*contentView;
@property (assign)	IBOutlet	NSButton		*previousPageButton;
@property (assign)	IBOutlet	NSButton		*nextPageButton;

@property (assign)				ArchiveTaskMode	mode;
@property (readwrite, copy)		NSString		*file;
@property (assign)				int				compressionLevel;
@property (assign)				BOOL			shouldBeProtected;
@property (assign)				BOOL			passwordNeverEntered;
@property (assign)				BOOL			passwordRepetitionNeverEntered;
@property (readwrite, copy)		NSString		*password;
@property (readwrite, copy)		NSString		*passwordRepetition;
@property (assign)				BOOL			shouldBeSplitted;
@property (assign)				BOOL			pieceSizeNeverEntered;
@property (assign)				float			pieceSize;
@property (assign)				int				pieceSizeUnit;
@property (readwrite, assign)	NSMutableArray	*filesToArchive;

@property (assign)	IBOutlet	NSImageView		*compressionLevelWarningImage;
@property (assign)	IBOutlet	NSTextField		*compressionLevelWarningLabel;
@property (assign)	IBOutlet	NSImageView		*passwordRepetitionWarningImage;
@property (assign)	IBOutlet	NSTextField		*passwordRepetitionWarningLabel;
@property (assign)	IBOutlet	NSImageView		*passwordWarningImage;
@property (assign)	IBOutlet	NSTextField		*passwordWarningLabel;
@property (assign)	IBOutlet	NSButton		*splitCheckbox;
@property (assign)	IBOutlet	NSTextField		*filesToArchiveLabel;

-(void)showCompleteWizard;
-(void)showCreateWizard;
-(void)showAddWizard;
-(void)showWindowWithPage:(int)startingPage;
-(IBAction)previousPageButtonClicked:(id)sender;
-(IBAction)nextPageButtonClicked:(id)sender;
-(IBAction)quitButtonClicked:(id)sender;
-(void)updateNavigationButtons;
-(void)loadPage:(int)pageNumber;
-(void)unloadCurrentPage;
-(BOOL)currentPageReady;
-(IBAction)userChoseMode:(id)sender;
-(IBAction)userWantsToChoseFile:(id)sender;
-(IBAction)userChoseCompressionLevel:(id)sender;
-(void)displayOrHideCompressionWarning;
-(IBAction)userToggledPassword:(id)sender;
-(BOOL)isPasswordCorrect;
-(BOOL)IsPasswordRepetitionCorrect;
-(void)displayOrHidePasswordWarnings;
-(IBAction)userToggledSplitting:(id)sender;
-(BOOL)pieceSizeCorrect;
-(void)userAddedFilesToArchive:(NSNotification *)notification;

@end
