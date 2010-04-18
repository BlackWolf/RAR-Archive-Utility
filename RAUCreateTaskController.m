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




@interface RAUCreateTaskController ()
@property (readwrite, copy)		NSArray			*filesToArchive;
@end
#pragma mark -




@implementation RAUCreateTaskController
#pragma mark -
@synthesize filesToArchive, targetRarfileArgument, compressionLevelArgument, pieceSizeArgument;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive {
	if (self = [super init]) {
		self.ETAFirstHalfFactor			= 1.45;
		self.filesToArchive				= _filesToArchive;
		self.targetRarfileArgument		= nil;
		self.compressionLevelArgument	= 3;
		self.pieceSizeArgument			= 0;
	}
	return self;
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	[super initView];
	
	//Show self.file's icon together with the archiving indicator
	[self.viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFileType:@"rar"]];
	[self.viewController.fileIconArchivingIndicator setHidden:NO];
	
	[self.delegate taskControllerIsReady:self];
}

-(void)didFinish {
	//As we potentially copy a lot here, do it in a seperate thread
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (self.task.result == TaskResultOK) {
			
			/* Get the path and filename where the created rarfiles need to end up */
			
			NSString *targetPath;
			NSString *targetFilename;
			if (self.targetRarfileArgument != nil) {
				targetPath		= self.targetRarfileArgument.withoutFilename;
				targetFilename	= self.targetRarfileArgument.filename;
			}
			else {
				NSString *firstArchivedFilePathString = (NSString *)[self.filesToArchive objectAtIndex:0];
				BOOL firstArchivedFileIsDirectory = [RAUAuxiliary isStringPathDirectory:firstArchivedFilePathString];
				RAUPath *firstArchivedFilePath = [RAUPath pathWithString:firstArchivedFilePathString isDirectory:firstArchivedFileIsDirectory];
				
				targetPath = firstArchivedFilePath.withoutFilename;
				
				if ([self.filesToArchive count] == 1) { //only a single file was compressed - name the rarfile(s) like that file
					targetFilename = firstArchivedFilePath.filename;
				} else {
					targetFilename = @"Archive";
				}
			}
			RAUPath *targetFile = [RAUPath pathWithDirectory:[targetPath stringByAppendingPathComponent:targetFilename]];
			
			/* Go through all created rarfiles, and get their target path (which is targetPath/targetFilename.extensions). When we have
			 all target Paths in a single array, we can finally determine the unique suffix we need */
			
			NSArray *createdFiles = [fileManager contentsOfDirectoryAtPath:self.createTask.tmpPath.completePath error:nil];
			NSMutableArray *createdFilePaths = [NSMutableArray arrayWithCapacity:1];
			NSMutableArray *targetFilePaths = [NSMutableArray arrayWithCapacity:1];
			
			for (NSString *createdFile in createdFiles) {
				NSString *createdFilePathString = [self.createTask.tmpPath.completePath stringByAppendingPathComponent:createdFile];
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
				[fileManager moveItemAtPath:createdFilePath.completePath
									 toPath:finalFilePathString
									  error:nil];
				
				if (firstFileCopied == nil) firstFileCopied = [RAUPath pathWithFile:finalFilePathString];
			}
			[RAUAuxiliary revealInFinder:firstFileCopied];
		}
		[fileManager removeItemAtPath:self.createTask.tmpPath.completePath error:nil]; //remove tmp-dir
		
		[self performSelectorOnMainThread:@selector(callSuperDidFinish) withObject:nil waitUntilDone:NO];
		
		[autoreleasePool release];
	});
}
-(void)callSuperDidFinish { 
	[super didFinish];
}

-(void)dealloc {
	self.filesToArchive			= nil;
	self.targetRarfileArgument	= nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark The RAUArchiveTask
@synthesize createTask;

-(RAUCreateTask *)createTask {
	return (RAUCreateTask *)self.task;
}

-(void)taskWillLaunch {
	RAUCreateTask *_task = [[RAUCreateTask alloc] initWithFilesToArchive:filesToArchive];
	self.task = _task;
	[_task release];
	
	[self.createTask setPasswordArgument:self.passwordArgument];
	[self.createTask setCompressionLevelArgument:self.compressionLevelArgument];
	[self.createTask setPieceSizeArgument:self.pieceSizeArgument];
}

/* Automatically invoked when the Task updates its progress */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	if (self.createTask.numberOfFiles > 0) {
		[self.viewController.progress	setIndeterminate:NO]; 
		[self.viewController.partsLabel	setHidden:NO];
	
		NSString *runtimeString = [self getETAString];
		
		NSString *completeString;
		if (self.createTask.numberOfFiles > 1) { //more than one file - we need the "file x of y label"
			[self.viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Archiving %d files", nil), self.createTask.numberOfFiles]];
			
			//numberOfFiles can be wrong. Even if it is, never show something like "File 11 of 10"
			int numberOfFiles = self.createTask.numberOfFiles;
			if (self.createTask.currentFile > numberOfFiles) numberOfFiles = self.createTask.currentFile;
			
			NSString *fileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d", nil), self.createTask.currentFile, numberOfFiles];
			completeString = [NSString stringWithFormat:@"%@ - %@", fileString, runtimeString];
		} else {
			[self.viewController.statusLabel setStringValue:NSLocalizedString(@"Archiving 1 file", nil)];
			
			completeString = runtimeString;
		}
		[self.viewController.partsLabel setStringValue:completeString];
		
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
