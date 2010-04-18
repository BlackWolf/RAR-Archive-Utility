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




@interface RAUCheckTask ()
@property (readwrite, retain)	RAURarfile		*rarfile;
@property (readwrite)			CheckTaskResult	detailedResult;
@end
#pragma mark -




@implementation RAUCheckTask

#pragma mark -
@synthesize rarfile, detailedResult;

-(id)initWithFile:(RAURarfile *)_rarfile {
	if (self = [super init]) {
		self.rarfile			= _rarfile;
		self.detailedResult		= CheckTaskResultNone;
		self.passwordArgument	= nil;
	}
	return self;
}

-(void)dealloc {
	self.rarfile			= nil;
	self.passwordArgument	= nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark The NSTask
@synthesize passwordArgument;

-(void)taskWillLaunch {
	[super taskWillLaunch];
	
	NSArray *arguments;
	
	NSString *passwordArgumentString = @"-p-"; //"-p-" means: no password
	if (self.passwordArgument != nil) passwordArgumentString = [NSString stringWithFormat:@"-p%@", self.passwordArgument];
	
	arguments = [NSArray arrayWithObjects:@"t", passwordArgumentString, self.rarfile.path.completePath, nil]; //"t" is test
	
	[self.task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"unrar" ofType:@""]]; //Path to unrar executable
	[self.task setArguments:arguments]; 
	
	//We have all the info we can gather after a second - terminate to save time. 
	//If the infos are gathered earlier, the task terminates by itself
	[self performSelector:@selector(terminateTask) withObject:nil afterDelay:0.75];
}

#pragma mark -
#pragma mark Parsing Output

-(void)parseNewOutput:(NSString *)output {
	[super parseNewOutput:output];
	
	if ([output rangeOfString:@"is not RAR archive"].location != NSNotFound
		|| [output rangeOfString:@"No such file or directory"].location != NSNotFound) {
		self.detailedResult = CheckTaskResultArchiveInvalid;
	}
	
	if ([output rangeOfString:@"Enter password (will not be echoed) "].location != NSNotFound) {
		self.detailedResult = CheckTaskResultPasswordInvalid;
	}
	
	if ([output rangeOfString:@"password incorrect ?"].location != NSNotFound) {
		self.detailedResult = CheckTaskResultPasswordInvalid;
	}
}

@end
