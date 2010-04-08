//
//  RAUAddTask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h"


@class RAURarfile;
@interface RAUAddTask : RAUTask {
	RAURarfile	*rarfile;
	NSArray		*filesToArchive;
	int			currentFile;
	int			numberOfFiles;
	NSString	*passwordArgument;
	int			compressionLevelArgument;
}

@property (readonly, retain)	RAURarfile		*rarfile;
@property (readonly, copy)		NSArray			*filesToArchive;
@property (readonly)			int				currentFile;
@property (readonly)			int				numberOfFiles;
@property (readwrite, copy)		NSString		*passwordArgument;
@property (readwrite)			int				compressionLevelArgument;

-(id)initWithFilesToArchive:(NSArray *)files withRarfile:(RAURarfile *)existingRarfile;


@end
