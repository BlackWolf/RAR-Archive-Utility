//
//  Rarfile.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Create a rarfile with the path to an existing file
// When the rarfile is created, it automatically launches an instance of ExtractTask to check if the provided file is valid or password
// protected. When it gathered the results, it sends a Notification */

#import "RAURarfile.h"
#import "RAUExtractTask.h"


@implementation RAURarfile
@synthesize fullPath, path, name, multipartExtension, extension, checkTask, isValid, isPasswordProtected, numberOfParts;

-(id)initWithFile:(NSString *)file {
	if (self = [super init]) {
		self.fullPath			= file;
		self.path				= [file stringByDeletingLastPathComponent];
		self.name				= [[file lastPathComponent] stringByDeletingPathExtension];
		self.multipartExtension	= [self.name pathExtension]; 
		self.extension			= [[file lastPathComponent] pathExtension];
		
		if (self.multipartExtension != nil) self.name = [self.name stringByDeletingPathExtension];
		
		//Create a task to check the file for validation and pwd
		self.checkTask = [[RAUExtractTask alloc] initWithFile:self mode:ExtractTaskModeCheck];
		
		[[NSNotificationCenter defaultCenter] //Listen to when the check finishes
		 addObserver:self
		 selector:@selector(fileCheckFinished:)
		 name:TaskDidFinishNotification
		 object:self.checkTask];
		
		[self.checkTask launchTask];	
	}
	return self;
}

/* Automatically invoked when checkTask finished. Fills the instance variables of the rarfile and sends a notification */
-(void)fileCheckFinished:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskDidFinishNotification object:self.checkTask];
	
	isValid				= !(self.checkTask.result == TaskResultArchiveInvalid);
	isPasswordProtected = (self.checkTask.result == TaskResultPasswordInvalid);
	
	//If the file is valid, see if it is multiparted and how many party it has
	numberOfParts = 0;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//First, check for the naming convention name.partXX.rar
	NSArray *filesAtPath = [fileManager contentsOfDirectoryAtPath:self.path error:nil];
	if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"part[0-9]+"] evaluateWithObject:self.multipartExtension]) {
		NSPredicate *isPart = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"%@.part[0-9]+.%@", self.name, self.extension]];
		for (NSString *fileAtPath in filesAtPath) {
			if ([isPart evaluateWithObject:fileAtPath] == YES) numberOfParts++;
		}
	} else if ([self.multipartExtension length] > 0) {
		//This prevents a wrong multipartExt for a file like name.something.rar (name should be name.something, multipartExt empty)
		self.name = [self.name stringByAppendingString:[NSString stringWithFormat:@".%@",self.multipartExtension]];
		self.multipartExtension = @"";
	}
	
	//Now for the naming convention name.rXX
	if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"r[0-9]+"] evaluateWithObject:self.extension] && numberOfParts == 0) {
		NSPredicate *isPart = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"%@.r[0-9]+", self.name]];
		for (NSString *fileAtPath in filesAtPath) {
			if ([isPart evaluateWithObject:fileAtPath] == YES) numberOfParts++;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RarfileCompletedNotification object:self];
}

-(void)dealloc {
	[fullPath			release];
	[path				release];
	[name				release];
	[multipartExtension	release];
	[extension			release];
	[self.checkTask		release];
	
	[super dealloc];
}

@end
