//
//  RAUAuxiliary.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 30.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Some auxiliary methods and definitions that can be useful everywhere
//

#import "RAUAuxiliary.h"
#import "RAUPath.h"


@implementation RAUAuxiliary

#pragma mark -
#pragma mark Getting unique files
/* The following methods are meant to create unique, usable filenames (so no file with that name already exists). This is done by inserting
 a numeric suffix between the filename and the extension (if name.ext1.ext2 already exists it uses name 1.ext1.ext2) */

/* This returns a suffix that can be used for all files in filePaths to make them unique in the path specified by path. filePaths is an
 array of RAUPath's */
+(NSString *)uniqueSuffixForFilenames:(NSArray *)filePaths inPath:(RAUPath *)path {
	NSFileManager	*fileManager			= [NSFileManager defaultManager];
	BOOL			allFine					= NO;
	int				currentSuffix			= 0;
	NSString		*currentSuffixString	= @"";
	
	while (allFine == NO) { //if the current suffix works for all files, allFine is YES
		allFine = YES;
		
		for (RAUPath *filePath in filePaths) {
			NSString *filePathWithSuffix = [RAUAuxiliary stringPathForFilename:filePath inPath:path withSuffix:currentSuffixString];

			if ([fileManager fileExistsAtPath:filePathWithSuffix] == YES) {
				allFine = NO;
				currentSuffix++;
				currentSuffixString = [NSString stringWithFormat:@" %d", currentSuffix];
				break;
			}
		}
	}
	
	return currentSuffixString;
}

/* Returns a unique path for the filename of file in path */
+(RAUPath *)uniquePathForFilename:(RAUPath *)file inPath:(RAUPath *)path {
	NSString *suffix = [RAUAuxiliary uniqueSuffixForFilenames:[NSArray arrayWithObject:file] inPath:path];
	NSString *uniquePathString = [RAUAuxiliary stringPathForFilename:file inPath:path withSuffix:suffix];
	return [RAUPath pathWithString:uniquePathString isDirectory:file.isDirectory];
}

+(RAUPath *)uniquePathForStringFilename:(NSString *)file inStringPath:(NSString *)path isDirectory:(BOOL)shouldBeDirectory {
	NSString *newPathString = [path stringByAppendingPathComponent:file];
	RAUPath *newPath = [RAUPath pathWithString:newPathString isDirectory:shouldBeDirectory];
	return [RAUAuxiliary uniquePathForFilename:newPath inPath:newPath];
}

/* Returns a unique path in the temp-directory of the OS */
+(RAUPath *)uniqueTemporaryPath {
	NSString *tmpPathString = [NSTemporaryDirectory() stringByAppendingPathComponent:@"RAU"];
	RAUPath *tmpPath = [RAUPath pathWithDirectory:tmpPathString];
	return [RAUAuxiliary uniquePathForFilename:tmpPath inPath:tmpPath];
}

/* Puts together a filename, path and suffix and returns the complete filepath including the filname as a string */
+(NSString *)stringPathForFilename:(RAUPath *)file inPath:(RAUPath *)path withSuffix:(NSString *)suffix {
	return [NSString stringWithFormat:@"%@%@%@",
			[path.withoutFilename stringByAppendingPathComponent:file.filename],
			suffix,
			file.completeExtension];
}

#pragma mark -
#pragma mark Counting files

/* Takes a path as a string and returns the number of files in it and all subdirectories */
+(int)filesInStringPath:(NSString *)path {
	NSFileManager			*fileManager	= [NSFileManager defaultManager];
	NSDirectoryEnumerator	*dirEnumerator	= [fileManager enumeratorAtPath:path];
	
	return [[dirEnumerator allObjects] count]+1; //+1 because we want to count the path itself as well
}
+(int)filesInPath:(RAUPath *)path {
	return [self filesInStringPath:path.complete];
}

#pragma mark -
#pragma mark Stuff

/* Uses an applescript to reveal path in finder */
+(void)revealInFinder:(RAUPath *)path {
	//Tell finder to select path (via AppleScript). Don't select if path is the desktop or on the desktop
	NSString *pathToDesktop = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
	if ([path.withoutFilename isEqualToString:pathToDesktop] == NO && [[path.withoutFilename stringByDeletingLastPathComponent] isEqualToString:pathToDesktop] == NO) {
		//This C-Script converts from normal paths to HFS-Paths ("HD:Users:Me:Something") (found via google)
		CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path.complete, kCFURLPOSIXPathStyle, YES);
		CFStringRef hfsPath = CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
		
		NSString *scriptSourceCode = [NSString stringWithFormat:@"tell application \"Finder\" to reveal \"%@\"", hfsPath];
		if (url) CFRelease(url);
		if (hfsPath) CFRelease(hfsPath);
		
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSourceCode];
		[appleScript executeAndReturnError:nil];
		[appleScript release];
	}	
}

@end