//
//  RAUCreateTask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h"
#import "RAUTaskPrivates.h"

@class RAUPath;
@interface RAUCreateTask : RAUTask {
	NSArray		*filesToArchive;
	RAUPath		*tmpPath;
	int			currentFile;
	int			numberOfFiles;
	NSString	*passwordArgument;
	int			compressionLevelArgument;
	int			pieceSizeArgument;
}

@property (readonly, copy)		NSArray		*filesToArchive;
@property (readonly, copy)		RAUPath		*tmpPath;
@property (readonly)			int			currentFile;
@property (readonly)			int			numberOfFiles;
@property (readwrite, copy)		NSString	*passwordArgument;
@property (readwrite)			int			compressionLevelArgument;
@property (readwrite)			int			pieceSizeArgument;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive;

@end
