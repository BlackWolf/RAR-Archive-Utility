//
//  RAUArchiveWizardController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RAUArchiveWizardController, RAUTaskController;
@protocol RAUArchiveWizardControllerDelegate
-(void)archiveWizardDidClose:(RAUArchiveWizardController *)wizardController finishedSuccessfully:(BOOL)finishedSuccessfully;
-(void)archiveWizard:(RAUArchiveWizardController *)wizardController createdTaskController:(RAUTaskController *)createdController;
@end

typedef enum {
	WizardModeCreate		=	0,
	WizardModeAdd			=	1
} WizardMode;

typedef enum {
	FileUnitKB	= 0,
	FileUnitMB	= 1,
	FileUnitGB	= 2
} FileUnit;

#define LASTPAGE 4




@interface RAUArchiveWizardController : NSWindowController <NSWindowDelegate> {
	id<RAUArchiveWizardControllerDelegate>	delegate;
	BOOL			isShown;
	int				firstPage;
	int				currentPage;
	BOOL			finishedSuccessfully;
	
	//Global UI
	NSTextField		*pageTitleLabel;
	NSView			*contentViewWrapper;
	NSView			*contentView;
	NSButton		*previousPageButton;
	NSButton		*nextPageButton;
	
	//Binded to UI
	WizardMode		mode;
	NSString		*file;
	int				compressionLevel;
	BOOL			shouldBeProtected;
	NSString		*password;
	NSString		*passwordRepetition;
	BOOL			shouldBeSplitted;
	float			pieceSize;
	FileUnit		pieceSizeUnit;
	NSMutableArray	*filesToArchive;
	
	//Page-specific variables
	BOOL			passwordNeverEntered;
	BOOL			passwordRepetitionNeverEntered;
	BOOL			pieceSizeNeverEntered;
	
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

@property (readwrite, assign)				id<RAUArchiveWizardControllerDelegate>	delegate;
@property (readonly)						BOOL			isShown;

@property (readwrite, assign)	IBOutlet	NSTextField		*pageTitleLabel;
@property (readwrite, assign)	IBOutlet	NSView			*contentViewWrapper;
@property (readwrite, assign)	IBOutlet	NSView			*contentView;
@property (readwrite, assign)	IBOutlet	NSButton		*previousPageButton;
@property (readwrite, assign)	IBOutlet	NSButton		*nextPageButton;

@property (readonly)						WizardMode		mode;
@property (readonly, copy)					NSString		*file;
@property (readonly)						int				compressionLevel;
@property (readonly)						BOOL			shouldBeProtected;
@property (readonly, copy)					NSString		*password;
@property (readonly, copy)					NSString		*passwordRepetition;
@property (readonly)						BOOL			shouldBeSplitted;
@property (readonly)						float			pieceSize;
@property (readonly)						FileUnit		pieceSizeUnit;
@property (readonly, retain)				NSMutableArray	*filesToArchive;

@property (readwrite, assign)	IBOutlet	NSImageView		*compressionLevelWarningImage;
@property (readwrite, assign)	IBOutlet	NSTextField		*compressionLevelWarningLabel;
@property (readwrite, assign)	IBOutlet	NSImageView		*passwordRepetitionWarningImage;
@property (readwrite, assign)	IBOutlet	NSTextField		*passwordRepetitionWarningLabel;
@property (readwrite, assign)	IBOutlet	NSImageView		*passwordWarningImage;
@property (readwrite, assign)	IBOutlet	NSTextField		*passwordWarningLabel;
@property (readwrite, assign)	IBOutlet	NSButton		*splitCheckbox;
@property (readwrite, assign)	IBOutlet	NSTextField		*filesToArchiveLabel;

-(void)showWindowWithPage:(int)_firstPage mode:(WizardMode)_mode;
-(void)showCompleteWizard;
-(void)showCreateWizard;
-(void)showAddWizard;
-(IBAction)previousPageButtonPressed:(id)sender;
-(IBAction)nextPageButtonPressed:(id)sender;
-(IBAction)quitButtonPressed:(id)sender;
-(IBAction)userChoseMode:(id)sender;
-(IBAction)userWantsToChoseFile:(id)sender;
-(IBAction)userChoseCompressionLevel:(id)sender;
-(IBAction)userToggledPassword:(id)sender;
-(IBAction)userToggledSplitting:(id)sender;

@end
