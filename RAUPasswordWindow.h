//
//  RAUPasswordWindowController.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 11.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RAUPasswordWindow;
@protocol RAUPasswordWindowDelegate
@optional
-(void)passwordWindowOKButtonPressed:(RAUPasswordWindow *)passwordWindow;
-(void)passwordWindowCancelButtonPressed:(RAUPasswordWindow *)passwordWindow;
@end



@interface RAUPasswordWindow : NSWindow {
	id<RAUPasswordWindowDelegate>	delegate;
	NSTextField						*titleLabel;
	NSTextField						*passwordTextField;
	NSButton						*OKButton;
	NSButton						*cancelButton;
}

@property (readwrite, assign)				id<RAUPasswordWindowDelegate>	delegate;
@property (readwrite, assign)	IBOutlet	NSTextField						*titleLabel;
@property (readwrite, assign)	IBOutlet	NSTextField						*passwordTextField;
@property (readwrite, assign)	IBOutlet	NSButton						*OKButton;
@property (readwrite, assign)	IBOutlet	NSButton						*cancelButton;

-(IBAction)passwordWindowOKButtonPressed:(id)sender;
-(IBAction)passwordWindowCancelButtonPressed:(id)sender;

@end
