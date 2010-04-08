//
//  RAUCreateTaskController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 04.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This creates the controller for an RAUCreateTask. With this you can create a new rarfile by providing files to archive. This controller
// also gives you an UI that is always updated to the current state of the task. The controller is also responsible for copying the created
// rarfile(s), either to the location of the first archived file (with the name Archive.rar) or to a location of your choice (if the
// targetRarfileArgument is specified)
//

#import "RAUCreateTaskController.h"
#import "RAUCreateTask.h"
#import "RAUTaskViewController.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"

@implementation RAUCreateTaskController
@synthesize filesToArchive, targetRarfileArgument, compressionLevelArgument, pieceSizeArgument;

-(id)initWithFilesToArchive:(NSArray *)files {
	if (self = [super init]) {
		filesToArchive				= [files copy];
		compressionLevelArgument	= 3;
		pieceSizeArgument			= 0;
		ETAFirstHalfFactor			= 1.45;
	}
	return self;
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	[super initView];
	
	//Show self.file's icon together with the archiving indicator
	[viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFileType:@"rar"]];
	[viewController.fileIconArchivingIndicator setHidden:NO];
	
	[delegate taskControllerIsReady:self];
}

-(void)didFinish {
	//As we potentially copy a lot here, do it in a seperate thread
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (task.result == TaskResultOK) {
			
			/* Get the path and filename where the created rarfiles need to end up */
			
			NSString *targetPath;
			NSString *targetFilename;
			if (targetRarfileArgument != nil) {
				targetPath = targetRarfileArgument.withoutFilename;
				targetFilename = targetRarfileArgument.filename;
			}
			else {
				NSString *firstArchivedFilePathString = (NSString *)[filesToArchive objectAtIndex:0];
				BOOL firstArchivedFileIsDirectory;
				[fileManager fileExistsAtPath:firstArchivedFilePathString isDirectory:&firstArchivedFileIsDirectory];
				RAUPath *firstArchivedFilePath = [RAUPath pathWithString:firstArchivedFilePathString isDirectory:firstArchivedFileIsDirectory];
				
				targetPath = firstArchivedFilePath.withoutFilename;
				
				if ([filesToArchive count] == 1) { //only a single file was compressed - name the rarfile(s) like that file
					targetFilename = firstArchivedFilePath.filename;
				} else {
					targetFilename = @"Archive";
				}
			}
			RAUPath *targetFile = [RAUPath pathWithDirectory:[targetPath stringByAppendingPathComponent:targetFilename]];
			
			/* Go through all created rarfiles, and get their target path (which is targetPath/targetFilename.extensions). When we have
			 all target Paths in a single array, we can finally determine the unique suffix we need */
			
			NSArray *createdFiles = [fileManager contentsOfDirectoryAtPath:self.createTask.tmpPath.complete error:nil];
			NSMutableArray *createdFilePaths = [NSMutableArray arrayWithCapacity:1];
			NSMutableArray *targetFilePaths = [NSMutableArray arrayWithCapacity:1];
			
			for (NSString *createdFile in createdFiles) {
				NSString *createdFilePathString = [self.createTask.tmpPath.complete stringByAppendingPathComponent:createdFile];
				RAUPath *createdFilePath = [RAUPath pathWithFile:createdFilePathString];
				NSString *targetFilePathString = [targetFile.withoutExtensions stringByAppendingString:createdFilePath.completeExtension];
				RAUPath *targetFilePath = [RAUPath pathWithFile:targetFilePathString];
				
				[createdFilePaths addObject:createdFilePath];
				[targetFilePaths addObject:targetFilePath];
			}
			NSString *suffix = [RAUAuxiliary uniqueSuffixForFilenames:targetFilePaths inPath:targetFile];
			
			/* Now that we have the suffix, we can copy all the created files to their destination */
			
			RAUPath *firstFileCopied = nil;
			for (RAUPath *createdFilePath in createdFilePaths) {
				NSString *targetFilePathString = [targetFile.withoutExtensions stringByAppendingString:createdFilePath.completeExtension];
				RAUPath *targetFilePath = [RAUPath pathWithFile:targetFilePathString];

				NSString *finalFilePathString = [RAUAuxiliary stringPathForFilename:targetFilePath inPath:targetFilePath withSuffix:suffix];
				[fileManager moveItemAtPath:createdFilePath.complete
									 toPath:finalFilePathString
									  error:nil];
				
				if (firstFileCopied == nil) firstFileCopied = [RAUPath pathWithFile:finalFilePathString];
			}
			[RAUAuxiliary revealInFinder:firstFileCopied];
		}
		[fileManager removeItemAtPath:self.createTask.tmpPath.complete error:nil]; //remove tmp-dir
		
		[self performSelectorOnMainThread:@selector(callSuperDidFinish) withObject:nil waitUntilDone:NO];
		
		[autoreleasePool release];
	});
}
-(void)callSuperDidFinish { 
	[super didFinish];
}

-(void)dealloc {
	[filesToArchive			release];
	[targetRarfileArgument	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The RAUArchiveTask
@synthesize createTask;

-(RAUCreateTask *)createTask {
	return (RAUCreateTask *)task;
}

-(void)taskWillLaunch {
	task = [[RAUCreateTask alloc] initWithFilesToArchive:filesToArchive];
	[self.createTask setPasswordArgument:passwordArgument];
	[self.createTask setCompressionLevelArgument:compressionLevelArgument];
	[self.createTask setPieceSizeArgument:pieceSizeArgument];
}

/* Automatically invoked when the Task updates its progress */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	if (self.createTask.numberOfFiles > 0) {
		[viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Archiving %d files", nil), self.createTask.numberOfFiles]];
		[viewController.progress	setIndeterminate:NO]; 
		[viewController.partsLabel	setHidden:NO];
	
		NSString *runtimeString = [self getETAString];
		
		NSString *completeString;
		if (self.createTask.numberOfFiles > 1) { //more than one file - we need the "file x of y label"
			//numberOfFiles can be wrong. Even if it is, never show something like "File 11 of 10"
			int numberOfFiles = self.createTask.numberOfFiles;
			if (self.createTask.currentFile > numberOfFiles) numberOfFiles = self.createTask.currentFile;
			
			NSString *fileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d", nil), self.createTask.currentFile, numberOfFiles];
			completeString = [NSString stringWithFormat:@"%@ - %@", fileString, runtimeString];
		} else {
			completeString = runtimeString;
		}
		[viewController.partsLabel setStringValue:completeString];
		
		[super taskProgressWasUpdated:updatedTask];
	}
}

#pragma mark -
#pragma mark Rarfile & Password

/* We overwrite this because rarfile path is not used in this controller. We redirect it to targetRarfileArgument */
-(void)setRarfilePath:(RAUPath *)value {
	[targetRarfileArgument release];
	targetRarfileArgument = [value copy];
}

/* We overwrite this because for the createController, we don't need to check the password or anything, it's just an argument */
-(void)setPasswordArgument:(NSString *)value {
	[passwordArgument release];
	passwordArgument = [value copy];
}

@end
