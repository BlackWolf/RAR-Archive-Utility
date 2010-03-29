//
//  RAUFloatStringTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This transforms a float 0 to an empty string and vice versa. Also makes sure "," and "." in the string is accepted as comma
//

#import <Cocoa/Cocoa.h>


@interface RAUFloatStringTransformer : NSValueTransformer {
}
@end




@implementation RAUFloatStringTransformer

+(Class)transformedValueClass { 
	return [NSString class]; 
}

+(BOOL)allowsReverseTransformation { 
	return YES;
}

/* From float to string */
-(id)transformedValue:(id)value {
	if (value == nil) return nil; //Just in case
	
	float floatValue;
	if ([value respondsToSelector:@selector(floatValue)]) floatValue = [value floatValue];
	else return nil;
	
	if (floatValue == 0) return nil;
	else return [NSString stringWithFormat:@"%f", floatValue];
}

/* From string to float */
-(id)reverseTransformedValue:(id)value {
	//Note: We always need to return objects, so we return NSNumbers here
	if (value == nil) return [NSNumber numberWithFloat:0];
	
	//Assuming we are transforming a string, replace ',' with '.' to make sure we get the float the user expects
	if ([value isKindOfClass:[NSString class]]) {
		NSMutableString *stringValue = [NSMutableString stringWithString:(NSString *)value];
		[stringValue replaceOccurrencesOfString:@"," withString:@"." options:NSLiteralSearch range:NSMakeRange(0,[stringValue length])];
		return [NSNumber numberWithFloat:[stringValue floatValue]];
	} 
	else return [NSNumber numberWithFloat:0];
}

@end
