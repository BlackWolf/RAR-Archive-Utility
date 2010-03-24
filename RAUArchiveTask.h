//
//  Rarer.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 08.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h"


typedef enum {
	ArchiveTaskModeCreate		=	0,
	ArchiveTaskModeAdd			=	1
} ArchiveTaskMode;


@class RAURarfile;
@interface RAUArchiveTask : RAUTask {
	NSArray			*files;
	NSString		*pathToNewRarfile;
	RAURarfile		*fileToModify;
	int				compressionLevel;
	int				splitSize;
	ArchiveTaskMode	mode;
	NSString		*tempArchiveLocation;
	NSString		*password;
}

@property (readwrite, copy)		NSArray			*files;
@property (readwrite, copy)		NSString		*pathToNewRarfile;
@property (readwrite, assign)	RAURarfile		*fileToModify;
@property (readonly)			int				compressionLevel;
@property (readonly)			int				splitSize;
@property (readonly)			ArchiveTaskMode	mode;
@property (readwrite, copy)		NSString		*tempArchiveLocation;
@property (readwrite, copy)		NSString		*password;

-(id)initWithFiles:(NSArray *)sourceFiles rarfileToModify:(RAURarfile *)existingRarfile password:(NSString *)filePassword compressionLevel:(int)compression;
-(id)initWithFiles:(NSArray *)sourceFiles rarfileToCreate:(NSString *)newRarfile password:(NSString *)filePassword compressionLevel:(int)compression splitIntoPiecesOfSize:(int)pieceSize;

@end
