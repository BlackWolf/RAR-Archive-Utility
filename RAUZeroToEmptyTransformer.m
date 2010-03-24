//
//  RAUZeroToEmptyTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAUZeroToEmptyTransformer : NSValueTransformer {
}
@end




@implementation RAUZeroToEmptyTransformer

/* Returns the class returned by transformedValue: */
+(Class)transformedValueClass { 
	return [NSString class]; 
}

/* We allow transformation in both directions - number to string and string to number */
+(BOOL)allowsReverseTransformation { 
	return YES;
}

/* Transformation from number to string */
-(id)transformedValue:(id)value {
	if (value == nil) return nil; //Just in case
	
	//If we can gather an floatValue from value, take it, otherwise return nothing
	float floatValue;
	if ([value respondsToSelector:@selector(floatValue)]) floatValue = [value floatValue];
	else return nil;
	
	//The actual conversion: If we have 0, return nothing so 0 isn't displayed
	if (floatValue == 0) return nil;
	else return [NSString stringWithFormat:@"%f", floatValue];
}

/* Transformation from String to Number. Needed so a nil value is interpreted as 0 */
-(id)reverseTransformedValue:(id)value {
	//Note: We always need to return objects, so we return NSNumbers here
	if (value == nil) return [NSNumber numberWithFloat:0];
	
	//Assuming we have are transforming a string, replace ',' with '.' to make sure we get the float the user expects
	NSMutableString *stringValue = [NSMutableString stringWithString:(NSString *)value];
	[stringValue replaceOccurrencesOfString:@"," withString:@"." options:NSLiteralSearch range:NSMakeRange(0,[stringValue length])];
	return [NSNumber numberWithFloat:[stringValue floatValue]];
	
	//return [NSNumber numberWithFloat:0];
}

@end
