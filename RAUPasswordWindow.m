//
//  RAUPasswordWindowController.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 11.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This class is pretty much just a container for all the UI elements found on the password window
//

#import "RAUPasswordWindow.h"




@implementation RAUPasswordWindow
@synthesize delegate;
@synthesize titleLabel, passwordTextField, OKButton, cancelButton;

-(IBAction)passwordWindowOKButtonPressed:(id)sender {
	[delegate passwordWindowOKButtonPressed:self];
}

-(IBAction)passwordWindowCancelButtonPressed:(id)sender {
	[delegate passwordWindowCancelButtonPressed:self];
}

@end
