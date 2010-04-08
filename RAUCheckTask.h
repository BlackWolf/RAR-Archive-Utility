//
//  RAUCheckTask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 31.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h"


#define CheckTaskDidFinishNotification	@"CheckTaskDidFinishNotification"
typedef enum {
	CheckTaskResultNone					= 0,
	CheckTaskResultArchiveInvalid		= 1,
	CheckTaskResultPasswordInvalid		= 2
} CheckTaskResult;


@class RAURarfile;
@interface RAUCheckTask : RAUTask {
	RAURarfile		*rarfile;
	CheckTaskResult	detailedResult;
	NSString		*passwordArgument;
}

@property (readonly, retain)	RAURarfile		*rarfile;
@property (readonly)			CheckTaskResult	detailedResult;
@property (readwrite, copy)		NSString		*passwordArgument;

-(id)initWithFile:(RAURarfile *)sourceFile;

@end
