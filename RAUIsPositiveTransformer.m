//
//  RAUIsPositiveTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAUIsPositiveTransformer : NSValueTransformer {
}
@end




@implementation RAUIsPositiveTransformer

/* Returns the class returned by transformedValue: */
+(Class)transformedValueClass { 
	return [NSNumber class]; 
}

/* We allow transformation in both directions - number to string and string to number */
+(BOOL)allowsReverseTransformation { 
	return NO;
}

/* Transformation from number to string */
-(id)transformedValue:(id)value {
	NSNumber *no = [NSNumber numberWithInt:0];
	NSNumber *yes = [NSNumber numberWithInt:1];
	
	if (value == nil) return no;
	
	//If we can gather an intValue from value, take it
	if ([value respondsToSelector:@selector(intValue)]) {
		if ([value intValue] > 0) return yes;
		else return no;
	}
	else return no;
}

/* Transformation from String to Number. Needed so a nil value is interpreted as 0 */
/*
-(id)reverseTransformedValue:(id)value {
	//Note: We always need to return objects, so we return NSNumbers here
	if (value == nil) return [NSNumber numberWithInt:0];
	
	//If we can get an intValue from value, return it, otherwise return 0
	if ([value respondsToSelector:@selector(intValue)]) return [NSNumber numberWithInt:[value intValue]];
	
	return [NSNumber numberWithInt:0];
}*/

@end
