//
//  RAUAddTaskController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 07.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"


@class RAUAddTask;
@interface RAUAddTaskController : RAUTaskController {
	NSArray			*filesToArchive;
	int				compressionLevelArgument;
	RAUAddTask		*addTask;
}

@property (readonly, copy)		NSArray			*filesToArchive;
@property (readwrite)			int				compressionLevelArgument;
@property (readonly)			RAUAddTask		*addTask;

-(id)initWithFilesToArchive:(NSArray *)files inRarfile:(RAUPath *)aRarfile;

@end
