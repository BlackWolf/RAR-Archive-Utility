//
//  RAURarfile.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 02.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// An instance of this class represents an existing rarfile on the users hard drive. It checks the rarfile for validation and
// password-protection. It can also check if a password is correct for a rarfile and return the result. When it is done doing it's
// initial check and when it's done checking for a password, it sends a notification
//

#import "RAURarfile.h"
#import "RAUCheckTask.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"


@implementation RAURarfile

#pragma mark -
@synthesize path, isValid, isPasswordProtected, numberOfParts;

-(id)initWithFilePath:(RAUPath *)filePath {
	if (self = [super init]) {
		path = [filePath copy];
		
		//Do the initial check to see if the rarfile is valid or password-protected
		RAUCheckTask *checkTask = [[RAUCheckTask alloc] initWithFile:self];
		[checkTask setDelegate:self];
		[checkTask launchTask];
	}
	return self;
}

/* Called when the initial check of the rarfile is done */
-(void)rarfileWasChecked:(RAUCheckTask *)checkTask {
	isValid				= (checkTask.detailedResult != CheckTaskResultArchiveInvalid);
	isPasswordProtected = (checkTask.detailedResult == CheckTaskResultPasswordInvalid);
	
	//See if file is multiparted and how many parts it has
	numberOfParts = 0;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//First, check for the naming convention name.partXX.rar
	NSArray *filesAtPath = [fileManager contentsOfDirectoryAtPath:path.withoutFilename error:nil];
	if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"part[0-9]+"] evaluateWithObject:path.multipartExtension]) {
		NSPredicate *isPart = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"%@.part[0-9]+.%@", path.filename, path.extension]];
		for (NSString *fileAtPath in filesAtPath) {
			if ([isPart evaluateWithObject:fileAtPath] == YES) numberOfParts++;
		}
	}
	
	//Now for the naming convention name.rXX
	if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"r[0-9]+"] evaluateWithObject:path.extension] && numberOfParts == 0) {
		NSPredicate *isPart = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"%@.r[0-9]+", path.filename]];
		for (NSString *fileAtPath in filesAtPath) {
			if ([isPart evaluateWithObject:fileAtPath] == YES) numberOfParts++;
		}
	}
	
	//If none of the previous did something, we have only a single part
	if (numberOfParts == 0) numberOfParts = 1;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RarfileWasCheckedNotification object:self];
}

-(void)dealloc {
	[path				release];
	[correctPassword	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Passwords
@synthesize passwordFound, correctPassword;

-(void)checkPassword:(NSString *)passwordToCheck {
	RAUCheckTask *checkTask = [[RAUCheckTask alloc] initWithFile:self];
	[checkTask setDelegate:self];
	[checkTask setPasswordArgument:passwordToCheck];
	[checkTask launchTask];
}

-(void)passwordWasChecked:(RAUCheckTask *)finishedTask {
	if (finishedTask.detailedResult != CheckTaskResultPasswordInvalid) {
		passwordFound = YES;
		[correctPassword release];
		correctPassword = [finishedTask.passwordArgument copy];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RarfilePasswordWasCheckedNotification object:self];
}

#pragma mark -
#pragma mark RAUTaskDelegate

/* RAUTaskDelegate method: Called when a checkTask finishes */
-(void)taskDidFinish:(RAUTask *)finishedTask {
	RAUCheckTask *checkTask = (RAUCheckTask *)finishedTask;
	
	if (checkTask.passwordArgument == nil) { //finishedTask was the initial checkTask
		[self rarfileWasChecked:checkTask];
	} else { //finishedTask was a password check
		[self passwordWasChecked:checkTask];
	}
	
	[checkTask release];
}

/* Just to satisfy the protocl */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {}

@end
