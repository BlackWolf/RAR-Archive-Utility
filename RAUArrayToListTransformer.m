//
//  RAUArrayToListTransformer.m
//  RAR-Archive Utility
//
//  Created by BlackWolf on 09.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAUArrayToListTransformer : NSValueTransformer {
}
@end




@implementation RAUArrayToListTransformer

/* Returns the class returned by transformedValue: */
+(Class)transformedValueClass { 
	return [NSString class]; 
}

/* We allow transformation in both directions - number to string and string to number */
+(BOOL)allowsReverseTransformation { 
	return NO;
}

/* Transformation from number to string */
-(id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSArray class]] == NO) return nil;
	
	return [value componentsJoinedByString:@"\n"];
}

@end

