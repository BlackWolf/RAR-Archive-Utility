//
//  RAURarfile.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 02.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTask.h" 


#define RarfileWasCheckedNotification			@"RarfileWasCheckedNotification"
#define RarfilePasswordWasCheckedNotification	@"RarfilePasswordWasCheckedNotification"




@class RAUPath;
@interface RAURarfile : NSObject <RAUTaskDelegate> {
	RAUPath		*path;
	BOOL		isValid;
	BOOL		isPasswordProtected;
	int			numberOfParts;
	BOOL		passwordFound;
	NSString	*correctPassword;
}

@property (readonly, copy)	RAUPath		*path;
@property (readonly)		BOOL		isValid;
@property (readonly)		BOOL		isPasswordProtected;
@property (readonly)		int			numberOfParts;
@property (readonly)		BOOL		passwordFound;
@property (readonly, copy)	NSString	*correctPassword;

-(id)initWithFilePath:(RAUPath *)_path;
-(void)checkPassword:(NSString *)passwordToCheck;

@end
