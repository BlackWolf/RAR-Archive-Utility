//
//  Debug.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Debug.h"


/* Provides a single instance for all other classes to write into the debug window */
@implementation Debug

static NSTextField *debugLabel;
+(void)log:(NSString *)message {
	[debugLabel setStringValue:[NSString stringWithFormat:@"%@ %@", [debugLabel stringValue], message]];
}

+(void)setDebugLabel:(NSTextField *)newDebugLabel {
	debugLabel = newDebugLabel;
}

@end
