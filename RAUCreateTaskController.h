//
//  RAUCreateTaskController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 04.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"
#import "RAUTaskControllerPrivates.h"




@class RAUCreateTask;
@interface RAUCreateTaskController : RAUTaskController {
	NSArray			*filesToArchive;
	RAUPath			*targetRarfileArgument;
	int				compressionLevelArgument;
	int				pieceSizeArgument;
	RAUCreateTask	*createTask;
}

@property (readonly, copy)		NSArray			*filesToArchive;
@property (readwrite, copy)		RAUPath			*targetRarfileArgument;
@property (readwrite)			int				compressionLevelArgument;
@property (readwrite)			int				pieceSizeArgument;
@property (readonly)			RAUCreateTask	*createTask;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive;

@end
