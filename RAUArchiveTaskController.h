//
//  ArchiveController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 12.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"


@class RAURarfile;
@interface RAUArchiveTaskController : RAUTaskController {
	NSArray		*files;
	NSString	*pathToNewRarfile;
	int			compressionLevel;
	int			splitSize;
	int			totalFilesToArchive;
}

@property (readwrite, copy)		NSArray			*files;
@property (readwrite, copy)		NSString		*pathToNewRarfile;
@property (readonly)			int				compressionLevel;
@property (readonly)			int				splitSize;
@property (readonly)			int				totalFilesToArchive;

-(id)initExistingRarfile:(NSString *)existingRarfile withFilesToAdd:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression;
-(id)initExistingRarfile:(NSString *)existingRarfile withFilesToAdd:(NSArray *)filesToArchive;
-(id)initNewRarfile:(NSString *)newRarfile withFiles:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression pieceSize:(int)pieceSize;
-(id)initNewRarfile:(NSString *)newRarfile withFiles:(NSArray *)filesToArchive password:(NSString *)filePassword compressionLevel:(int)compression;
-(id)initNewRarfileWithFiles:(NSArray *)filesToArchive;
-(void)initView;

@end
