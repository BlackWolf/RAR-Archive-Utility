//
//  Rartask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define TaskHasUpdatedProgressNotification	@"TaskHasUpdatedProgressNotification"
#define TaskDidFinishNotification			@"TaskDidFinishNotification"
typedef enum {
	TaskResultArchiveInvalid	=	0,
	TaskResultPasswordInvalid	=	1,
	TaskResultOK				=	2,
	TaskResultNone				=	3
} TaskResult;


@interface RAUTask : NSObject {
	NSTask			*task;
	NSFileHandle	*fileHandle;
	int				currentFile;
	int				progress;
	TaskResult		result;
}

@property (readwrite, assign)	NSTask			*task;
@property (readwrite, assign)	NSFileHandle	*fileHandle;
@property (readonly)			int				currentFile;
@property (readonly)			int				progress;
@property (readonly)			TaskResult		result;

-(void)taskWillLaunch;
-(void)launchTask;
-(void)taskDidLaunch;
-(void)receivedNewOutput:(NSNotification *)notification;
-(void)parseNewOutput:(NSString *)output;
-(int)parseProgressFromString:(NSString *)output;
-(void)terminateTask;
-(void)taskDidTerminate:(NSNotification *)notification;
-(void)willFinish;
-(void)didFinish;
-(void)sendDidFinishNotification;
-(NSString *)usableFilenameAtPath:(NSString *)path withName:(NSString *)name isDirectory:(BOOL)isDirectory;
-(NSString *)usableFilenameAtPath:(NSString *)path withName:(NSString *)name;
-(NSString *)usableSuffixAtPath:(NSString *)path withNames:(NSArray *)names;
-(void)revealInFinder:(NSString *)path;

@end
