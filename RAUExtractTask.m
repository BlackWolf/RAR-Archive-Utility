//
//  RAUExtractTask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Creates an "unrar" task that extracts the provided rarfile into a temporary directory. If the rarfile is password protected, the password 
// must be specified in passwordArgument. This should not be called directly, only via its controller
//

#import "RAUExtractTask.h"
#import "RAURarfile.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"


@implementation RAUExtractTask
@synthesize rarfile, tmpPath, currentPart, numberOfParts;

-(id)initWithFile:(RAURarfile *)sourceFile {
	if (self = [super init]) {
		rarfile			= [sourceFile retain];
		currentPart		= 0;
		numberOfParts	= rarfile.numberOfParts;
	}
	return self;
}

-(void)dealloc {
	[rarfile			release];
	[tmpPath			release];
	[passwordArgument	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument;

-(void)taskWillLaunch {
	[super taskWillLaunch];
	
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSArray			*arguments;
	
	NSString *passwordArgumentString = @"-p-"; //"-p-" means: no password
	if (passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", passwordArgument];
	
	arguments = [NSArray arrayWithObjects:@"x", passwordArgumentString, rarfile.path.complete, nil]; //"x" is extract
		
	[tmpPath release];
	tmpPath = [[RAUAuxiliary uniqueTemporaryPath] retain];
	[fileManager createDirectoryAtPath:tmpPath.complete withIntermediateDirectories:NO attributes:nil error:nil];
	[task setCurrentDirectoryPath:tmpPath.complete]; 
	
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"unrar" ofType:@""]]; //Path to unrar executable
	[task setArguments:arguments]; 
}

#pragma mark -
#pragma mark Parsing output

/* Adds things specific to this task to the basic output-parsing of RAUTask */
-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	if ([output rangeOfString:@"Extracting from "].location != NSNotFound) {
		//Allow max of 1 for currentPart before we have progress (unrar sometimes sends "Extracting from" too often at the beginning)
		if (progress == 0 && currentPart == 0) {
			currentPart++;
			[delegate taskProgressWasUpdated:self];
		}
		
		if (progress > 0) {
			//Count how often "Extracting from" is occuring in the current output
			NSArray *seperatedOutput = [output componentsSeparatedByString:@"Extracting from "];
			currentPart += [seperatedOutput count]-1;
			[delegate taskProgressWasUpdated:self];
		}
	}
}
	
@end
