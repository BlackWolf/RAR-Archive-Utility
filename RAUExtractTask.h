//
//  Unrarer.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h" 


typedef enum {
	ExtractTaskModeCheck	=	0,
	ExtractTaskModeExtract	=	1
} ExtractTaskMode;


@class RAURarfile;
@interface RAUExtractTask : RAUTask {
	RAURarfile		*file;
	ExtractTaskMode	mode;
	NSString		*password;
	NSString		*extractionPath;
}

@property (readwrite, assign)	RAURarfile		*file;
@property (readonly)			ExtractTaskMode	mode;
@property (readwrite, copy)		NSString		*password;
@property (readwrite, copy)		NSString		*extractionPath;

-(id)initWithFile:(RAURarfile *)targetFile mode:(ExtractTaskMode)taskMode password:(NSString *)taskPassword;
-(id)initWithFile:(RAURarfile *)targetFile mode:(ExtractTaskMode)taskMode;

@end
