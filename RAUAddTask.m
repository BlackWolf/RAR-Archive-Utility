//
//  RAUAddTask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Creates a "rar" task that adds files to an existing rar archive. You can specify several additional arguments. If the rarfile is
// password protected, the password must be specified in passwordArgument. This class should not be invoked directly, only via its
// controller
//

#import "RAUAddTask.h"
#import "RAURarfile.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"




@interface RAUAddTask ()
@property (readwrite, retain)	RAURarfile	*rarfile;
@property (readwrite, copy)		NSArray		*filesToArchive;
@property (readwrite)			int			currentFile;
@property (readwrite)			int			numberOfFiles;
@end


@implementation RAUAddTask

#pragma mark -
@synthesize rarfile, filesToArchive, currentFile, numberOfFiles;

-(id)initWithFilesToArchive:(NSArray *)_filesToArchive withRarfile:(RAURarfile *)_rarfile {
	if (self = [super init]) {
		self.rarfile					= _rarfile;
		self.filesToArchive				= _filesToArchive;
		self.currentFile				= 0;
		self.numberOfFiles				= 0;
		self.passwordArgument			= nil;
		self.compressionLevelArgument	= 0;
		
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
	self.rarfile			= nil;
	self.filesToArchive		= nil;
	self.passwordArgument	= nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument, compressionLevelArgument;

-(void)taskWillLaunch {	
	[super taskWillLaunch];
	
	//a:add ; u:update files; ep1:use relative paths; m:compressionLevel; v:split; hp:password; 
	NSMutableArray	*arguments = [NSMutableArray arrayWithObjects:@"a", @"-u", @"-ep1", nil]; 
	
	NSString *compressionLevelArgumentString = [NSString stringWithFormat:@"-m%d", self.compressionLevelArgument];
	[arguments addObject:compressionLevelArgumentString];
	
	NSString *passwordArgumentString = @"-p-"; //"-p-" means: no password
	if (self.passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", self.passwordArgument];
	[arguments addObject:passwordArgumentString];
	
	[arguments addObject:self.rarfile.path.completePath];
	
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
