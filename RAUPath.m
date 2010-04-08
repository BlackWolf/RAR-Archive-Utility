//
//  RAUPath.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 05.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Returns an object that contains information about a path to a file or directory
//

#import "RAUPath.h"


@implementation RAUPath

#pragma mark -
@synthesize complete, withoutFilename, filename, multipartExtension, extension;
@synthesize completeExtension, withoutExtensions, filenameWithExtensions, isDirectory;

-(id)initWithString:(NSString *)path isDirectory:(BOOL)shouldBeDirectory {
	if (self = [super init]) {
		complete = [path copy]; 
		withoutFilename = [[path stringByDeletingLastPathComponent] copy]; 
		
		if (isDirectory == NO) {
			//filename is just the name with no extensions, so remove extension and multipart extension if they exist
			filename			= [[[[path lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension] copy];
			extension			= [[path pathExtension] copy];
			multipartExtension	= [[[path stringByDeletingPathExtension] pathExtension] copy];
			
			//multipartExtension should only be "partXX". If it is anything else, it should be part of the filename
			if ([multipartExtension length] > 0
				&& [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"part[0-9]+"] evaluateWithObject:multipartExtension] == NO) {
				[filename			autorelease];
				[multipartExtension	autorelease];
				filename			= [[NSString alloc] initWithFormat:@"%@.%@", filename, multipartExtension];
				multipartExtension	= nil;
			}
			
			//Get the completeExtension, which is MPExtension and extension including dots
			if ([extension length] > 0) {
				if ([multipartExtension length] > 0) {
					completeExtension = [[NSString alloc] initWithFormat:@".%@.%@", multipartExtension, extension];
				} else {
					completeExtension = [[NSString alloc] initWithFormat:@".%@", extension];
				}
			} else {
				completeExtension = nil;
			}
		} else { //directories have no extension
			filename			= [[path lastPathComponent] copy];
			extension			= nil;
			multipartExtension	= nil;
			completeExtension	= nil;
		}
		
		withoutExtensions = [[withoutFilename stringByAppendingPathComponent:filename] copy];
		filenameWithExtensions = [[NSString alloc] initWithFormat:@"%@%@", filename, completeExtension];
		isDirectory = shouldBeDirectory;
	}
	return self;
}
-(id)initWithFile:(NSString *)pathToFile {
	return [self initWithString:pathToFile isDirectory:NO];
}
-(id)initWithDirectory:(NSString *)pathToDirectory {
	return [self initWithString:pathToDirectory isDirectory:YES];
}

/* Autoreleased inits */
+(id)pathWithString:(NSString *)path isDirectory:(BOOL)shouldBeDirectory {
	return [[[RAUPath alloc] initWithString:path	isDirectory:shouldBeDirectory] autorelease];
}
+(id)pathWithFile:(NSString *)pathToFile {
	return [[[RAUPath alloc] initWithFile:pathToFile] autorelease];
}
+(id)pathWithDirectory:(NSString *)pathToDirectory {
	return [[[RAUPath alloc] initWithDirectory:pathToDirectory] autorelease];
}

-(id)copyWithZone:(NSZone *)zone {
	return [[RAUPath alloc] initWithString:complete isDirectory:isDirectory];
}

-(void)dealloc {
	[complete				release];
	[withoutFilename		release];
	[filename				release];
	[multipartExtension		release];
	[extension				release];
	[completeExtension		release];
	[withoutExtensions		release];
	[filenameWithExtensions	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Getters
/* Write getters for all properties so that they return an empty string instead of nil */

-(NSString *)complete {
	if (complete == nil)	return @"";
	else					return complete;
}

-(NSString *)withoutFilename {
	if (withoutFilename == nil)	return @"";
	else						return withoutFilename;
}

-(NSString *)filename {
	if (filename == nil)	return @"";
	else					return filename;
}

-(NSString *)multipartExtension {
	if (multipartExtension == nil)	return @"";
	else							return multipartExtension;
}

-(NSString *)completeExtension {
	if (completeExtension == nil)	return @"";
	else							return completeExtension;
}

-(NSString *)withoutExtensions {
	if (withoutExtensions == nil)	return @"";
	else							return withoutExtensions;
}

-(NSString *)filenameWithExtensions {
	if (filenameWithExtensions == nil)	return @"";
	else								return filenameWithExtensions;
}

@end
