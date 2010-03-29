//
//  RAUArrayToListTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//
// This transforms an array into a string. The string is a list of all the entries of the array
//

#import <Cocoa/Cocoa.h>


@interface RAUArrayToListTransformer : NSValueTransformer {
}
@end




@implementation RAUArrayToListTransformer

+(Class)transformedValueClass { 
	return [NSString class]; 
}

+(BOOL)allowsReverseTransformation { 
	return NO;
}

/* From array to string */
-(id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSArray class]] == NO) return nil;
	
	return [value componentsJoinedByString:@"\n"];
}

@end

