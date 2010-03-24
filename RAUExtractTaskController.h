//
//  ExtractController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 12.02.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RAUTaskController.h"


@interface RAUExtractTaskController : RAUTaskController {
}

-(id)initWithFile:(NSString *)filePath;
-(void)initView;

@end
