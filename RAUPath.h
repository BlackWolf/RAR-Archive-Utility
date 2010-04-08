//
//  RAUPath.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAUPath : NSObject {
	NSString	*complete;
	NSString	*withoutFilename;
	NSString	*filename;
	NSString	*multipartExtension;
	NSString	*extension;
	
	NSString	*completeExtension;
	NSString	*withoutExtensions;
	NSString	*filenameWithExtensions;
	BOOL		isDirectory;
}

@property (readonly, copy)	NSString	*complete;
@property (readonly, copy)	NSString	*withoutFilename;
@property (readonly, copy)	NSString	*filename;
@property (readonly, copy)	NSString	*multipartExtension;
@property (readonly, copy)	NSString	*extension;

@property (readonly, copy)	NSString	*completeExtension;
@property (readonly, copy)	NSString	*withoutExtensions;
@property (readonly, copy)	NSString	*filenameWithExtensions;
@property (readonly)		BOOL		isDirectory;

-(id)initWithString:(NSString *)path isDirectory:(BOOL)shouldBeDirectory;
-(id)initWithFile:(NSString *)pathToFile;
-(id)initWithDirectory:(NSString *)pathToDirectory;
+(id)pathWithString:(NSString *)path isDirectory:(BOOL)shouldBeDirectory;
+(id)pathWithFile:(NSString *)pathToFile;
+(id)pathWithDirectory:(NSString *)pathToDirectory;

@end
