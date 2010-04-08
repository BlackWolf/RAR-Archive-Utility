//
//  RAUExtractTaskController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This creates the controller for an RAUExtractTask. With this, you can extract a rarfile, have a view with the current state of the
// rarfile and a delegate that receives messages. Also, when the extraction finishes, the extracted files are copied to the location
// of the rarfile (if multiple files were extracted a new folder is created)
//

#import "RAUExtractTaskController.h"
#import "RAURarfile.h"
#import "RAUExtractTask.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"
#import "RAUTaskViewController.h"


@implementation RAUExtractTaskController

#pragma mark -

-(id)initWithFilePath:(RAUPath *)pathToExtract {
	if (self = [super init]) {
		self.rarfilePath	= pathToExtract; //Setting this automatically sets rarfile and either invokes launchTask or asks for password
		ETAFirstHalfFactor	= 1.7;
	}
	return self;
}

-(id)initWithStringPath:(NSString *)pathToExtract {
	RAUPath *path = [RAUPath pathWithFile:pathToExtract];
	return [self initWithFilePath:path];
}

/* Called by init with performSelector:, which means this is called after the view was fully initialized */
-(void)initView {
	[super initView];
	
	//Show rarfile's icon
	[viewController.fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:rarfile.path.complete]];
}

-(void)didFinish {
	//As we potentially copy a lot here, do this in a seperate thread
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(queue,^{
		NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (self.extractTask.result == TaskResultOK) { 
			NSArray *extractedFiles = [fileManager contentsOfDirectoryAtPath:self.extractTask.tmpPath.complete error:nil];
			RAUPath *targetPath;
			
			//If we extracted multiple files, we copy all the files in a new directory
			if ([extractedFiles count] > 1) { 
				//Determine the target directory
				targetPath = [RAUAuxiliary uniquePathForStringFilename:rarfile.path.filename 
														  inStringPath:rarfile.path.withoutFilename 
														   isDirectory:YES];
				
				[fileManager createDirectoryAtPath:targetPath.complete withIntermediateDirectories:YES attributes:nil error:nil];
				
				for (NSString *extractedFile in extractedFiles) {
					[fileManager moveItemAtPath:[self.extractTask.tmpPath.complete	stringByAppendingPathComponent:extractedFile]
										 toPath:[targetPath.complete				stringByAppendingPathComponent:extractedFile] 
										  error:nil];
				}
			} else { //only a single file was extracted
				NSString *extractedFile = (NSString *)[extractedFiles objectAtIndex:0];
				NSString *extractedFilePathString = [self.extractTask.tmpPath.complete stringByAppendingPathComponent:extractedFile];
				
				BOOL extractedFileIsDirectory;
				[fileManager fileExistsAtPath:extractedFilePathString isDirectory:&extractedFileIsDirectory];
				RAUPath *extractedFilePath = [RAUPath pathWithString:extractedFilePathString isDirectory:extractedFileIsDirectory];
				
				targetPath = [RAUAuxiliary uniquePathForFilename:extractedFilePath inPath:rarfile.path];
				
				//If extracted file was no directory, simply copy it
				if (extractedFileIsDirectory == NO) {
					[fileManager moveItemAtPath:extractedFilePath.complete
										 toPath:targetPath.complete 
										  error:nil];
				} else { //extracted file was a directory - copy all its contents to a new directory with a unique name
					NSArray *extractedSubFiles = [fileManager contentsOfDirectoryAtPath:extractedFilePath.complete error:nil];
					
					[fileManager createDirectoryAtPath:targetPath.complete withIntermediateDirectories:YES attributes:nil error:nil];
					
					for (NSString *extractedSubFile in extractedSubFiles) {
						[fileManager moveItemAtPath:[extractedFilePath.complete	stringByAppendingPathComponent:extractedSubFile]
											 toPath:[targetPath.complete		stringByAppendingPathComponent:extractedSubFile] 
											  error:nil];
					}
				}
			}
			[RAUAuxiliary revealInFinder:targetPath];
		}
		[fileManager removeItemAtPath:self.extractTask.tmpPath.complete error:nil]; 
		
		[self performSelectorOnMainThread:@selector(callSuperDidFinish) withObject:nil waitUntilDone:NO];
		
		[autoreleasePool release];
	});
}
-(void)callSuperDidFinish { 
	[super didFinish];
}

#pragma mark -
#pragma mark The RAUExtractTask
@synthesize extractTask;


-(RAUExtractTask *)extractTask {
	return (RAUExtractTask *)task;
}

-(void)taskWillLaunch {
	//Overwrite the standard RAUTask in self.task with an RAUExtractTask
	task = [[RAUExtractTask alloc] initWithFile:rarfile];
	[self.extractTask setPasswordArgument:passwordArgument];
	
	[self taskProgressWasUpdated:task];
}

/* Automatically invoked when the Task updates its progress */
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask {
	[viewController.statusLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Extracting \"%@.%@\"", nil), rarfile.path.filename, rarfile.path.extension]];
	[viewController.progress	setIndeterminate:NO]; 
	[viewController.partsLabel	setHidden:NO];
	
	NSString *runtimeString = [self getETAString];
	
	NSString *completeString;
	if (rarfile.numberOfParts > 1) { //Multiple parts - we need the "Part x of y" string
		//numberOfParts can be wrong. Even if it is, never show something like "Part 4 of 3"
		int numberOfParts = self.extractTask.numberOfParts;
		if (self.extractTask.currentPart > self.extractTask.numberOfParts) numberOfParts = self.extractTask.currentPart;
		
		NSString *partsString = [NSString stringWithFormat:NSLocalizedString(@"Part %d of %d", nil), self.extractTask.currentPart, numberOfParts];
		completeString = [NSString stringWithFormat:@"%@ - %@", partsString, runtimeString];
	} else { //Single part - only show ETA
		completeString = runtimeString;
	}
	[viewController.partsLabel setStringValue:completeString];
	
	[super taskProgressWasUpdated:updatedTask];
}

@end
