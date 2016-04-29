//
//  WILDIrisCloseFilter.h
//  Stacksmith
//
//  Created by Uli Kusterer on 12.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface WILDTransitionFilter : CIFilter
{
    CIImage   *inputImage;
    CIImage   *inputTargetImage;
    NSNumber  *inputTime;
}

@property (retain) CIImage*		inputImage;
@property (retain) CIImage*		inputTargetImage;
@property (retain) NSNumber*	inputTime;

+(void)	registerFiltersFromFile: (NSString*)inPListFile;	// Calls registerForDisplayName:filterName: for each WILDxxx filter listed in the file.
+(void)	registerForDisplayName: (NSString*)inDisplayName filterName: (NSString*)inFilterName;

@end