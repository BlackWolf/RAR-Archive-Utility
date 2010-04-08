//
//  RAUCheckTask.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 31.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Launches an "unrar" task that checks if a rarfile is valid or password protected. If passwordArgument is set, this checks if that
// password is correct. This is the only RAUTask that should be created directly, there is no controller for this class
//

#import "RAUCheckTask.h"
#import "RAURarfile.h"
#import "RAUPath.h"
#import "RAUAuxiliary.h"

@implementation RAUCheckTask
@synthesize rarfile, detailedResult;

-(id)initWithFile:(RAURarfile *)sourceFile {
	if (self = [super init]) {
		rarfile			= [sourceFile retain];
		detailedResult	= CheckTaskResultNone;
	}
	return self;
}

-(void)dealloc {
	[rarfile			release]; 
	[passwordArgument	release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument;

-(void)taskWillLaunch {
	[super taskWillLaunch];
	
	NSArray *arguments;
	
	NSString *passwordArgumentString = @"-p-"; //"-p-" means: no password
	if (passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", passwordArgument];
	
	arguments = [NSArray arrayWithObjects:@"t", passwordArgumentString, rarfile.path.complete, nil]; //"t" is test
	
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"unrar" ofType:@""]]; //Path to unrar executable
	[task setArguments:arguments]; 
	
	//We have all the info we can gather after a second - terminate to save time. 
	//If the infos are gathered earlier, the task terminates by itself
	[self performSelector:@selector(terminateTask) withObject:nil afterDelay:1.0];
}

#pragma mark -
#pragma mark Parsing Output

-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	if ([output rangeOfString:@"is not RAR archive"].location != NSNotFound
		|| [output rangeOfString:@"No such file or directory"].location != NSNotFound) {
		detailedResult = CheckTaskResultArchiveInvalid;
	}
	
	if ([output rangeOfString:@"password incorrect ?"].location != NSNotFound) {
		detailedResult = CheckTaskResultPasswordInvalid;
	}
}

@end
