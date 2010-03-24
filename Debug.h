//
//  Debug.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Debug : NSObject {

}

+(void)log:(NSString *)message;
+(void)setDebugLabel:(NSTextField *)newDebugLabel;

@end
