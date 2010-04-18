//
//  RAUExtractTask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h" 
#import "RAUTaskPrivates.h"




@class RAURarfile, RAUPath;
@interface RAUExtractTask : RAUTask {
	RAURarfile		*rarfile;
	RAUPath			*tmpPath;
	int				currentPart;
	int				numberOfParts;
	NSString		*passwordArgument;
}

@property (readonly, retain)	RAURarfile	*rarfile;
@property (readonly, copy)		RAUPath		*tmpPath;
@property (readonly)			int			currentPart;
@property (readonly)			int			numberOfParts;
@property (readwrite, copy)		NSString	*passwordArgument;

-(id)initWithFile:(RAURarfile *)_rarfile;

@end
