//
//  Rarfile.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define RarfileCompletedNotification	@"RarfileCompletedNotification"


@class RAUExtractTask;
@interface RAURarfile : NSObject {
	NSString		*fullPath;
	NSString		*path;
	NSString		*name;
	NSString		*multipartExtension;
	NSString		*extension;
	RAUExtractTask	*checkTask;
	BOOL			isValid;
	BOOL			isPasswordProtected;
	int				numberOfParts;
}

@property (readwrite, copy)		NSString		*fullPath;
@property (readwrite, copy)		NSString		*path;
@property (readwrite, copy)		NSString		*name;
@property (readwrite, copy)		NSString		*multipartExtension;
@property (readwrite, copy)		NSString		*extension;
@property (readwrite, assign)	RAUExtractTask	*checkTask;
@property (readonly)			BOOL			isValid;
@property (readonly)			BOOL			isPasswordProtected;
@property (readonly)			int				numberOfParts;

-(id)initWithFile:(NSString *)file;
-(void)fileCheckFinished:(NSNotification *)notification;

@end
