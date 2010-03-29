//
//  Unrarer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Subclass of RAUTask, represents an instance of the unrar executable which unrars files
//

#import "RAUExtractTask.h"
#import "RAURarfile.h"


@implementation RAUExtractTask

#pragma mark -
@synthesize file, mode, password, extractionPath;

-(id)initWithFile:(RAURarfile *)targetFile mode:(ExtractTaskMode)taskMode password:(NSString *)taskPassword {
	if (self = [super init]) {
		self.file		=	targetFile;
		mode			=	taskMode;
		self.password	=	taskPassword;
	}
	return self;
}
-(id)initWithFile:(RAURarfile *)targetFile mode:(ExtractTaskMode)taskMode {
	return [self initWithFile:targetFile mode:taskMode password:nil];
}

-(void)taskWillLaunch {
	[super taskWillLaunch];
	
	//Before launching self.task, create it here with all the arguments needed to actually extract something
	NSArray *arguments;
	
	NSString *passwordArgument = @"-p-"; //"-p-" means: no password
	if (self.password != nil) passwordArgument = [NSString stringWithFormat:@"-p%@", self.password];
	
	if (mode == ExtractTaskModeCheck) 
		arguments = [NSArray arrayWithObjects:@"t", passwordArgument, self.file.fullPath, nil]; //"t" is test
	if (mode == ExtractTaskModeExtract) { 
		arguments = [NSArray arrayWithObjects:@"x", passwordArgument, self.file.fullPath, nil]; //"x" is extract
		
		//We extract to a subdirectory of the temp-directory, which we create here. When the extraction terminates, we copy from there
		NSFileManager *fileManager = [NSFileManager defaultManager];
		self.extractionPath = [self usableFilenameAtPath:NSTemporaryDirectory() withName:self.file.name];
		[fileManager createDirectoryAtPath:self.extractionPath withIntermediateDirectories:NO attributes:nil error:nil];
		[self.task setCurrentDirectoryPath:self.extractionPath]; 
	}
	
	[self.task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"unrar" ofType:@""]]; //Path to unrar executable
	[self.task setArguments:arguments]; 
	
	//In Check mode, we have all the info we can gather (pwd and valid) after a second - terminate to save time
	//Note that, if the infos are gathered earlier, the task terminates by itself
	if (mode == ExtractTaskModeCheck)
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(terminateTask) userInfo:nil repeats:NO];
}

-(void)willFinish {
	[super willFinish];
	
	if (mode == ExtractTaskModeExtract) { 
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		//If we were successful in extracting all files ...
		if (self.task.terminationStatus == 0) { 
			NSArray *extractedFiles = [fileManager contentsOfDirectoryAtPath:self.extractionPath error:nil];
			
			//We copy the files from the temp directory to the final directory where the user wants the extracted files to end up
			NSString *finalPath;
			
			//If we extracted multiple files, we copy all the files to a newly created directory
			if ([extractedFiles count] > 1) { 
				finalPath = [self usableFilenameAtPath:self.file.path withName:self.file.name isDirectory:YES];
				[fileManager createDirectoryAtPath:finalPath withIntermediateDirectories:NO attributes:nil error:nil];
				
				//Copy from tmp dir to target dir
				for (NSString *extractedFile in extractedFiles) {
					[fileManager moveItemAtPath:[self.extractionPath stringByAppendingPathComponent:extractedFile]
										 toPath:[finalPath stringByAppendingPathComponent:extractedFile] error:nil];
				}
			} else { //Only a single file was extracted - we don't need to create a new directory to copy to
				NSString *extractedFile = (NSString *)[extractedFiles objectAtIndex:0];
				NSString *extractedFilePath = [self.extractionPath stringByAppendingPathComponent:extractedFile];
				BOOL extractedFileIsDirectory;
				[fileManager fileExistsAtPath:extractedFilePath isDirectory:&extractedFileIsDirectory];
				
				if (extractedFileIsDirectory == NO) {
					finalPath = [self usableFilenameAtPath:self.file.path withName:extractedFile];
					
					[fileManager moveItemAtPath:extractedFilePath
										 toPath:finalPath error:nil];
				} else { 
					finalPath = [self usableFilenameAtPath:self.file.path withName:extractedFile isDirectory:YES];
					[fileManager createDirectoryAtPath:finalPath withIntermediateDirectories:NO attributes:nil error:nil];
					extractedFiles = [fileManager contentsOfDirectoryAtPath:extractedFilePath error:nil];
					
					for (NSString *extractedFile in extractedFiles) {
						[fileManager moveItemAtPath:[extractedFilePath stringByAppendingPathComponent:extractedFile]
											 toPath:[finalPath stringByAppendingPathComponent:extractedFile] error:nil];
					}
				}
			}
			
			[self revealInFinder:finalPath];
		}
		
		[fileManager removeItemAtPath:self.extractionPath error:nil]; //Remove tmp dir
	}
}

-(void)dealloc {
	//[file release]; No release because file is the parent of Unrarer and retains it, we need to avoid a retain cycle
	[password		release];
	[extractionPath	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Parsing output

/* Adds things specific to this task to the basic output-parsing of RAUTask */
-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	if ([output rangeOfString:@"Extracting from "].location != NSNotFound) {
		//Allow max of 1 for currentFile before we have progress (unrar sometimes sends "Extracting from" too often at the beginning)
		if (progress == 0 && currentFile == 0) {
			currentFile++;
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskHasUpdatedProgressNotification object:self];
		}
		
		if (progress > 0) {
			//Count how often "Extracting from" is occuring in the current output
			NSArray *seperatedOutput = [output componentsSeparatedByString:@"Extracting from "];
			currentFile += [seperatedOutput count]-1;
			[[NSNotificationCenter defaultCenter] postNotificationName:TaskHasUpdatedProgressNotification object:self];
		}
	}
}

@end
