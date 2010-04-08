//
//  RAUCreateTask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Creates an "rar" task that creates a new rarfile that contains the files provided in the initialization. You can also provide several
// additional arguments. This class should not be created directly, only via its controller
//

#import "RAUCreateTask.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"

@implementation RAUCreateTask

#pragma mark -
@synthesize filesToArchive, tmpPath, currentFile, numberOfFiles;

-(id)initWithFilesToArchive:(NSArray *)files {
	if (self = [super init]) {
		filesToArchive				= [files copy];
		currentFile					= 0; 
		
		//Count the files we are archiving (including subfolders). Since this can take a while, do it in a seperate thread
		numberOfFiles = 0;
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
		dispatch_async(queue,^{
			NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
			
			for (NSString *fileToArchive in filesToArchive) {
				numberOfFiles += [RAUAuxiliary filesInStringPath:fileToArchive];
				[delegate performSelectorOnMainThread:@selector(taskProgressWasUpdated:) withObject:self waitUntilDone:NO];
			}
			
			[autoreleasePool release];
		});
	}
	return self;
}

-(void)dealloc {
	[filesToArchive		release];
	[tmpPath			release];
	[passwordArgument	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument, compressionLevelArgument, pieceSizeArgument;

-(void)taskWillLaunch {	
	[super taskWillLaunch];
	
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSMutableArray	*arguments;
	
	//a:add ; u:update files; ep1:use relative paths; m:compressionLevel; v:split; hp:password; 
	arguments = [NSMutableArray arrayWithObjects:@"a", @"-u", @"-ep1", nil]; 
	
	NSString *compressionLevelArgumentString = [NSString stringWithFormat:@"-m%d", compressionLevelArgument];
	[arguments addObject:compressionLevelArgumentString];
	
	if (pieceSizeArgument > 0) {
		NSString *pieceSizeArgumentString = [NSString stringWithFormat:@"-v%d", pieceSizeArgument];
		[arguments addObject:pieceSizeArgumentString];
	}
	
	if (passwordArgument != nil) [arguments addObject:[NSString stringWithFormat:@"-hp%@", passwordArgument]];
	
	[tmpPath release];
	tmpPath = [[RAUAuxiliary uniqueTemporaryPath] retain];
	[fileManager createDirectoryAtPath:tmpPath.complete withIntermediateDirectories:NO attributes:nil error:nil];
	[arguments addObject:[tmpPath.complete stringByAppendingPathComponent:@"Archive.rar"]];
	
	[arguments addObjectsFromArray:filesToArchive];
	
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"rar" ofType:@""]]; //Path to rar executable
	[task setArguments:arguments]; 
}

#pragma mark -
#pragma mark Parsing output

/* Adds things specific to this task to the basic output-parsing of RAUTask */
-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	NSArray *seperatedOutput = nil;
	if ([output rangeOfString:@"Adding "].location != NSNotFound) 
		seperatedOutput = [output componentsSeparatedByString:@"Adding "];
	if ([output rangeOfString:@"Updating "].location != NSNotFound) 
		seperatedOutput = [output componentsSeparatedByString:@"Updating "];
	if (seperatedOutput != nil) {
		currentFile += [seperatedOutput count]-1;
		[delegate taskProgressWasUpdated:self];
	}
	
}

@end
