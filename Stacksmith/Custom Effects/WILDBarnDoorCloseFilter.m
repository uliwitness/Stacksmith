//
//  WILDBarnDoorCloseFilter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 12.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDBarnDoorCloseFilter.h"
#import "UKHelperMacros.h"


@implementation WILDBarnDoorCloseFilter

@synthesize inputTime;
@synthesize inputImage;
@synthesize inputTargetImage;

static CIKernel *sIrisFilterKernel = nil;

+(void)	initialize
{
    [CIFilter registerFilterName: @"WILDBarnDoorCloseFilter"
        constructor: (id<CIFilterConstructor>)self
        classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
             @"Barn Door Close Effect", kCIAttributeFilterDisplayName,
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
		NSError		*theError = nil;
		NSString	*kernelName = @"WILDBarnDoorCloseFilter";
        NSString    *code = [NSString stringWithContentsOfFile: [bundle
                                pathForResource: kernelName ofType: @"cikernel"] encoding: NSUTF8StringEncoding error: &theError];
		if( !code )
		{
			NSLog( @"Couldn't load file '%@.cikernel': %@", kernelName, theError );
			[self autorelease];
			return nil;
		}
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
	DESTROY_DEALLOC(inputImage);
	DESTROY_DEALLOC(inputTargetImage);
	DESTROY_DEALLOC(inputTime);
	
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
