//
//  RAUTask.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 31.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
	TaskResultNone				= 0,
	TaskResultOK				= 1,
	TaskResultFailed			= 2
} TaskResult;

@class RAUTask;
@protocol RAUTaskDelegate
-(void)taskProgressWasUpdated:(RAUTask *)updatedTask;
-(void)taskDidFinish:(RAUTask *)finishedTask;
@optional
-(void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait; //NSObject implements this
@end




@interface RAUTask : NSObject {
	id<RAUTaskDelegate>	delegate;
	int					progress;
	TaskResult			result;
	NSTask				*task;
}

@property (readwrite, assign)	id<RAUTaskDelegate>	delegate;
@property (readonly)			int					progress;
@property (readonly)			TaskResult			result;
@property (readonly, retain)	NSTask				*task;

-(void)launchTask;
-(void)terminateTask;

@end