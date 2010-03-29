//
//  RAUIsPositiveTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This transforms an int into a boolean value determing if the int is positive
//

#import <Cocoa/Cocoa.h>


@interface RAUIsPositiveTransformer : NSValueTransformer {
}
@end




@implementation RAUIsPositiveTransformer

+(Class)transformedValueClass { 
	return [NSNumber class]; 
}

+(BOOL)allowsReverseTransformation { 
	return NO;
}

/* From number to string */
-(id)transformedValue:(id)value {
	NSNumber *no = [NSNumber numberWithInt:0];
	NSNumber *yes = [NSNumber numberWithInt:1];
	
	if (value == nil) return no;
	
	if ([value respondsToSelector:@selector(intValue)]) {
		if ([value intValue] > 0) return yes;
		else return no;
	}
	else return no;
}

@end
