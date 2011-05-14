//
//  WILDStretchFromBottomFilter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 12.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDStretchFromBottomFilter.h"
#import "UKHelperMacros.h"


@implementation WILDStretchFromBottomFilter

static CIKernel *sIrisFilterKernel = nil;

+(void)	initialize
{
    [CIFilter registerFilterName: @"WILDStretchFromBottomFilter"
        constructor: self
        classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
             @"Stretch From Bottom Effect", kCIAttributeFilterDisplayName,
             [NSArray arrayWithObjects:
                kCICategoryTransition, nil], kCIAttributeFilterCategories,
            nil]
            ];
}


+(CIFilter *)	filterWithName: (NSString *)name
{
    CIFilter  *filter = [[self alloc] init];
    return [filter autorelease];
}


-(id)	init
{
    if(sIrisFilterKernel == nil)
    {
        NSBundle    *bundle = [NSBundle bundleForClass: [self class]];
        NSString    *code = [NSString stringWithContentsOfFile: [bundle
                                pathForResource: @"WILDStretchFromBottomFilter"
                                ofType: @"cikernel"]];
        NSArray     *kernels = [CIKernel kernelsWithString: code];
 
        sIrisFilterKernel = [[kernels objectAtIndex: 0] retain];
    }
 
    self = [super init];
	if( self )
		inputTime = [[NSNumber numberWithDouble: 0.5] retain];
		
	return self;
}


-(void)	dealloc
{
	DESTROY(inputImage);
	DESTROY(inputTargetImage);
	DESTROY(inputTime);
	
    [super dealloc];
}


-(NSDictionary *)	customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.5], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeScalar,            kCIAttributeType,
            nil],                              kCIInputTimeKey, 
        nil];
}


-(CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage: inputImage];
	CISampler *target = [CISampler samplerWithImage: inputTargetImage];

    return [self apply: sIrisFilterKernel, src, target, inputTime, kCIApplyOptionDefinition, [src definition], nil];
}

@end
