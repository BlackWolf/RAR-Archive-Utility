//
//  RAUExtractTaskController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"
#import "RAUTaskControllerPrivates.h"




@class RAUExtractTask;
@interface RAUExtractTaskController : RAUTaskController {
	RAUExtractTask *extractTask;
}

@property (readonly)	RAUExtractTask	*extractTask;

-(id)initWithFilePath:(RAUPath *)_rarfilePath;
-(id)initWithStringPath:(NSString *)pathToExtract;

@end
