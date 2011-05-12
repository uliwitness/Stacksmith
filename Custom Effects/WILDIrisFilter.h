//
//  WILDIrisFilter.h
//  Stacksmith
//
//  Created by Uli Kusterer on 12.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface WILDIrisFilter : CIFilter
{
    CIImage   *inputImage;
    CIImage   *inputTargetImage;
    NSNumber  *percentage;
}

@property (retain) CIImage*		inputImage;
@property (retain) CIImage*		inputTargetImage;
@property (retain) NSNumber*	percentage;

@end