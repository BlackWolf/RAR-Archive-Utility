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




@interface RAUCreateTask ()
@property (readwrite, copy)		NSArray		*filesToArchive;
@property (readwrite, copy)		RAUPath		*tmpPath;
@property (readwrite)			int			currentFile;
@property (readwrite)			int			numberOfFiles;
@end




@implementation RAUCreateTask

#pragma mark -
@synthesize filesToArchive, tmpPath, currentFile, numberOfFiles;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive {
	if (self = [super init]) {
		self.filesToArchive				= _filesToArchive;
		self.tmpPath					= nil;
		self.currentFile				= 0; 
		self.numberOfFiles				= 0;
		self.passwordArgument			= nil;
		self.compressionLevelArgument	= 3;
		self.pieceSizeArgument			= 0;
		
		//Count the files we are archiving (including subfolders). Since this can take a while, do it in a seperate thread
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
		dispatch_async(queue,^{
			NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
			
			for (NSString *fileToArchive in self.filesToArchive) {
				self.numberOfFiles += [RAUAuxiliary filesInStringPath:fileToArchive];
				[self.delegate performSelectorOnMainThread:@selector(taskProgressWasUpdated:) withObject:self waitUntilDone:NO];
			}
			
			[autoreleasePool release];
		});
	}
	return self;
}

-(void)dealloc {
	self.filesToArchive		= nil;
	self.tmpPath			= nil;
	self.passwordArgument	= nil;
	
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
	
	NSString *compressionLevelArgumentString = [NSString stringWithFormat:@"-m%d", self.compressionLevelArgument];
	[arguments addObject:compressionLevelArgumentString];
	
	if (self.pieceSizeArgument > 0) {
		NSString *pieceSizeArgumentString = [NSString stringWithFormat:@"-v%d", self.pieceSizeArgument];
		[arguments addObject:pieceSizeArgumentString];
	}
	
	if (self.passwordArgument != nil) [arguments addObject:[NSString stringWithFormat:@"-hp%@", self.passwordArgument]];
	
	self.tmpPath = [RAUAuxiliary uniqueTemporaryPath];
	[fileManager createDirectoryAtPath:self.tmpPath.completePath withIntermediateDirectories:NO attributes:nil error:nil];
	[arguments addObject:[self.tmpPath.completePath stringByAppendingPathComponent:@"Archive.rar"]];
	
	[arguments addObjectsFromArray:self.filesToArchive];
	
	[self.task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"rar" ofType:@""]]; //Path to rar executable
	[self.task setArguments:arguments]; 
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
		self.currentFile += [seperatedOutput count]-1;
		[self.delegate taskProgressWasUpdated:self];
	}
	
}

@end
