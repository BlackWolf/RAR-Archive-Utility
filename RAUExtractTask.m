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




@interface RAUExtractTask ()
@property (readwrite, retain)	RAURarfile	*rarfile;
@property (readwrite, copy)		RAUPath		*tmpPath;
@property (readwrite)			int			currentPart;
@property (readwrite)			int			numberOfParts;
@end
#pragma mark -




@implementation RAUExtractTask

#pragma mark -
@synthesize rarfile, tmpPath, currentPart, numberOfParts;

-(id)initWithFile:(RAURarfile *)_rarfile {
	if (self = [super init]) {
		self.rarfile			= _rarfile;
		self.tmpPath			= nil;
		self.currentPart		= 0;
		self.numberOfParts		= self.rarfile.numberOfParts;
		self.passwordArgument	= nil;
	}
	return self;
}

-(void)dealloc {
	self.rarfile			= nil;
	self.tmpPath			= nil;
	self.passwordArgument	= nil;
	
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
	if (self.passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", self.passwordArgument];
	
	arguments = [NSArray arrayWithObjects:@"x", passwordArgumentString, self.rarfile.path.completePath, nil]; //"x" is extract
		
	self.tmpPath = [RAUAuxiliary uniqueTemporaryPath];
	[fileManager createDirectoryAtPath:self.tmpPath.completePath withIntermediateDirectories:NO attributes:nil error:nil];
	[self.task setCurrentDirectoryPath:self.tmpPath.completePath]; 
	
	[self.task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"unrar" ofType:@""]]; //Path to unrar executable
	[self.task setArguments:arguments]; 
}

#pragma mark -
#pragma mark Parsing output

/* Adds things specific to this task to the basic output-parsing of RAUTask */
-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	if ([output rangeOfString:@"Extracting from "].location != NSNotFound) {
		//Allow max of 1 for currentPart before we have progress (unrar sometimes sends "Extracting from" too often at the beginning)
		if (self.progress == 0 && self.currentPart == 0) {
			self.currentPart++;
			[self.delegate taskProgressWasUpdated:self];
		}
		
		if (self.progress > 0) {
			//Count how often "Extracting from" is occuring in the current output
			NSArray *seperatedOutput = [output componentsSeparatedByString:@"Extracting from "];
			self.currentPart += [seperatedOutput count]-1;
			[self.delegate taskProgressWasUpdated:self];
		}
	}
}
	
@end
