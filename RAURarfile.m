//
//  Rarfile.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 28.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// An instance of RAURarfile represents an existing rarfile on the users hard drive. When created, this class checks if the provided
// file is a valid archive, if it is password protected and if it is multiparted. Besides that, it's an easy way to access the different
// parts of the rarfiles path
//

#import "RAURarfile.h"
#import "RAUExtractTask.h"


#warning We probably want to rewrite this class, so we can create rarfiles from non-existing files (giving us path information etc.)
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
		
#warning We should create a TaskController here. This'd also allow us to replace the TaskDidFinishNotification with a method call to RAUTaskController
		//Create a task to check the file for validation and pwd
		self.checkTask = [[RAUExtractTask alloc] initWithFile:self mode:ExtractTaskModeCheck];
		
		//Listen to when the check finishes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(fileCheckFinished:)
													 name:TaskDidFinishNotification
												   object:self.checkTask];
		
		[self.checkTask launchTask];	
	}
	return self;
}

/* Automatically invoked when checkTask finished */
-(void)fileCheckFinished:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:TaskDidFinishNotification object:self.checkTask];
	
	isValid				= !(self.checkTask.result == TaskResultArchiveInvalid);
	isPasswordProtected = (self.checkTask.result == TaskResultPasswordInvalid);
	
	//See if it is multiparted and how many parts it has
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[fullPath			release];
	[path				release];
	[name				release];
	[multipartExtension	release];
	[extension			release];
	[checkTask			release];
	
	[super dealloc];
}

@end
