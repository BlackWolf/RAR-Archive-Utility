//
//  MainWindow.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 29.01.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAUMainWindow : NSWindow {
	NSTextField	*introLabel;
}

@property (assign)	IBOutlet	NSTextField	*introLabel;

-(void)expandBy:(int)expandBy animate:(BOOL)animate;
-(void)expandBy:(int)expandBy;
-(void)collapseBy:(int)collapseBy animate:(BOOL)animate;
-(void)collapseBy:(int)collapseBy;

@end
