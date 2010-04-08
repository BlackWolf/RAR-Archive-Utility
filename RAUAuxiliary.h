//
//  RAUAuxiliary.h
//  RAR-Archive Utility
//
//  Created by BlackWolf on 01.04.10.
//  Copyright 2010 Mario Schreiner. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RAUPath;
@interface RAUAuxiliary : NSObject {
}

+(NSString *)uniqueSuffixForFilenames:(NSArray *)filePaths inPath:(RAUPath *)path;
+(RAUPath *)uniquePathForFilename:(RAUPath *)file inPath:(RAUPath *)path;
+(RAUPath *)uniquePathForStringFilename:(NSString *)file inStringPath:(NSString *)path isDirectory:(BOOL)shouldBeDirectory;
+(RAUPath *)uniqueTemporaryPath;
+(NSString *)stringPathForFilename:(RAUPath *)file inPath:(RAUPath *)path withSuffix:(NSString *)suffix;
+(int)filesInStringPath:(NSString *)path;
+(int)filesInPath:(RAUPath *)path;
+(void)revealInFinder:(RAUPath *)path;

@end