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


@implementation RAUAddTask

#pragma mark -
@synthesize rarfile, filesToArchive, currentFile, numberOfFiles;

-(id)initWithFilesToArchive:(NSArray *)files withRarfile:(RAURarfile *)existingRarfile {
	if (self = [super init]) {
		rarfile						= [existingRarfile retain];
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
	[rarfile			release];
	[filesToArchive		release];
	[passwordArgument	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument, compressionLevelArgument;

-(void)taskWillLaunch {	
	[super taskWillLaunch];
	
	//a:add ; u:update files; ep1:use relative paths; m:compressionLevel; v:split; hp:password; 
	NSMutableArray	*arguments = [NSMutableArray arrayWithObjects:@"a", @"-u", @"-ep1", nil]; 
	
	NSString *compressionLevelArgumentString = [NSString stringWithFormat:@"-m%d", compressionLevelArgument];
	[arguments addObject:compressionLevelArgumentString];
	
	NSString *passwordArgumentString = @"-p-"; //"-p-" means: no password
	if (passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", passwordArgument];
	[arguments addObject:passwordArgumentString];
	
	[arguments addObject:rarfile.path.complete];
	
	[arguments addObjectsFromArray:filesToArchive];
	
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"rar" ofType:@""]]; //Path to rar executable
	[task setArguments:arguments]; 
	
	NSLog(@"%@", [arguments componentsJoinedByString:@" "]);
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
