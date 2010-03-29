//
//  Rarer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 08.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// Subclass of RAUTask. Represents an instance of the rar task that archives files
//

#import "RAUArchiveTask.h"
#import "RAURarfile.h"

@implementation RAUArchiveTask

#pragma mark -
@synthesize files, pathToNewRarfile, fileToModify, compressionLevel, splitSize, mode, tempArchiveLocation, password;

/* Init for adding files to a rarfile */
-(id)initWithFiles:(NSArray *)sourceFiles rarfileToModify:(RAURarfile *)existingRarfile password:(NSString *)filePassword compressionLevel:(int)compression {
	if (self = [super init]) {
		self.files			= sourceFiles;
		compressionLevel	= compression;
		
		if (existingRarfile == nil) {
			mode		= ArchiveTaskModeCreate;
			splitSize	= 0;
		} else {
			mode				= ArchiveTaskModeAdd;
			self.fileToModify	= existingRarfile;
			self.password		= filePassword;
		}
	}

	
	return self;
}

/* Init for creating a new rarfile */
-(id)initWithFiles:(NSArray *)sourceFiles rarfileToCreate:(NSString *)newRarfile password:(NSString *)filePassword compressionLevel:(int)compression splitIntoPiecesOfSize:(int)pieceSize {
	if (self = [super init]) {
		self.files = sourceFiles;
		compressionLevel = compression;
		splitSize = pieceSize;
		
		mode = ArchiveTaskModeCreate;
		self.pathToNewRarfile = newRarfile;
		self.password = filePassword;
	}
	return self;
}

-(void)taskWillLaunch {	
	[super taskWillLaunch];
	
	//Before launching self.task, create it here with all the arguments needed to actually compress something
	//a:add ; u:update files; ep1:relative path; m:compression; v:split; hp:password; 
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"a", @"-u", @"-ep1", [NSString stringWithFormat:@"-m%d", compressionLevel], nil]; 
	
	if (mode == ArchiveTaskModeCreate) {
		if (splitSize == 0) { //No split: Create an Archive.rar in the tmp-dir
			self.tempArchiveLocation = [self usableFilenameAtPath:NSTemporaryDirectory() withName:@"Archive.rar"];
			[arguments addObject:self.tempArchiveLocation];
		} else { //split: Create an "SplitArchive" folder in the tmp-dir and put all parts in there
			[arguments addObject:[NSString stringWithFormat:@"-v%d", splitSize]];
			
			NSString *usableDirectory = [self usableFilenameAtPath:NSTemporaryDirectory() withName:@"SplitArchive"];
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createDirectoryAtPath:usableDirectory withIntermediateDirectories:YES attributes:nil error:nil];
			
			NSString *targetFilename = [self.pathToNewRarfile lastPathComponent];
			self.tempArchiveLocation = [usableDirectory stringByAppendingPathComponent:targetFilename];
			[arguments addObject:self.tempArchiveLocation];
		}
		
		if (self.password != nil) [arguments addObject:[NSString stringWithFormat:@"-hp%@",self.password]];
	} else {
		NSString *passwordArgument = @"-p-"; //"-p-" means: no password
		if (self.password != nil) passwordArgument = [NSString stringWithFormat:@"-p%@", self.password];
		[arguments addObject:passwordArgument];
		[arguments addObject:self.fileToModify.fullPath];
	}
	[arguments addObjectsFromArray:self.files];
	
	[self.task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"rar" ofType:@""]]; //Path to rar executable
	[self.task setArguments:arguments]; 
}

-(void)willFinish {
	[super willFinish];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (self.task.terminationStatus == 0 && mode == ArchiveTaskModeCreate) { //Task finished successfully
		if (splitSize == 0) { 
			NSString *finalLocation;
			
			//If the task was initialized with a target location, use that
			if (self.pathToNewRarfile != nil) finalLocation = pathToNewRarfile;
			else { 
				NSString *firstArchivedFile = (NSString *)[self.files objectAtIndex:0];
				
				//If we only compressed one file, take the name of that file as the archive name. Otherwise use a generic "Archive.rar"
				if ([self.files count] == 1) {
					finalLocation = [self usableFilenameAtPath:[firstArchivedFile stringByDeletingLastPathComponent] withName:[NSString stringWithFormat:@"%@.rar",[firstArchivedFile lastPathComponent]]];
				} else {
					finalLocation = [self usableFilenameAtPath:[firstArchivedFile stringByDeletingLastPathComponent] withName:@"Archive.rar"];
				}
			}
			[fileManager moveItemAtPath:self.tempArchiveLocation
								 toPath:finalLocation error:nil];
			
			[self revealInFinder:finalLocation];
		} else { //We created a splitted archive
			NSString *tempArchivePath	= [self.tempArchiveLocation	stringByDeletingLastPathComponent];
			NSString *targetPath		= [self.pathToNewRarfile	stringByDeletingLastPathComponent];
			NSArray *splitArchiveFiles	= [fileManager				contentsOfDirectoryAtPath:tempArchivePath error:nil];
			
			//If we wanted to create a splitted archive, but ended up with just one part: Treat is like a non-splitted archive
			if ([splitArchiveFiles count] == 1) {
				splitSize = 0;
				[self willFinish];
			} else {
				NSString *firstFileCopied	= nil; //this is what we reveal in finder when we are done
				NSString *suffix			= [self usableSuffixAtPath:targetPath withNames:splitArchiveFiles];
				
				for (NSString *splitArchiveFile in splitArchiveFiles) {
					NSString *fileExtension				= [NSString stringWithFormat:@".%@.%@", [[splitArchiveFile stringByDeletingPathExtension] pathExtension], [splitArchiveFile pathExtension]];
					NSString *fileNameWithoutExtensions	= [[splitArchiveFile stringByDeletingPathExtension] stringByDeletingPathExtension];
					NSString *fileName					= [NSString stringWithFormat:@"%@%@%@", fileNameWithoutExtensions, suffix, fileExtension];
					
					[fileManager moveItemAtPath:[tempArchivePath stringByAppendingPathComponent:splitArchiveFile] 
										 toPath:[targetPath stringByAppendingPathComponent:fileName] error:nil];
					
					if (firstFileCopied == nil) firstFileCopied = [targetPath stringByAppendingPathComponent:fileName];
				}
				
				[self revealInFinder:firstFileCopied];
			}
			
			[fileManager removeItemAtPath:tempArchivePath error:nil]; //remove tmp-dir
		}
	}
	
	if (self.task.terminationStatus != 0 && mode == ArchiveTaskModeCreate) { //We did NOT finish successful
		//Remove tmp files
		if (splitSize == 0) [fileManager removeItemAtPath:tempArchiveLocation error:nil]; 
		else [fileManager removeItemAtPath:[self.tempArchiveLocation stringByDeletingLastPathComponent] error:nil];
	}
}

-(void)dealloc {
	[files					release];
	[pathToNewRarfile		release];
	[fileToModify			release];
	[tempArchiveLocation	release];
	[password				release];
	
	[super dealloc];
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
		[[NSNotificationCenter defaultCenter] postNotificationName:TaskHasUpdatedProgressNotification object:self];
	}
	
}

@end
