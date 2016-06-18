//
//  WILDTransitionFilter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 12.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDTransitionFilter.h"
#import "UKHelperMacros.h"


@interface WILDTransitionFilter ()

@property (retain) CIKernel	*	filterKernel;

@end


@implementation WILDTransitionFilter

@synthesize inputTime;
@synthesize inputImage;
@synthesize inputTargetImage;
@synthesize filterKernel;

static NSMutableDictionary<NSString*,CIKernel*>*	sFilterKernels = nil;


+(CIFilter *)	filterWithName: (NSString *)name
{
    CIFilter  *filter = [[self alloc] initWithName: name];
    return [filter autorelease];
}


-(id)	initWithName: (NSString*)kernelName
{
	if( !sFilterKernels )
		sFilterKernels = [NSMutableDictionary new];
	CIKernel	*	foundKernel = sFilterKernels[kernelName];
    if(foundKernel == nil)
    {
        NSBundle    *bundle = [NSBundle bundleForClass: [self class]];
		NSError		*theError = nil;
        NSString    *code = [NSString stringWithContentsOfFile: [bundle
                                pathForResource: kernelName ofType: @"cikernel"] encoding: NSUTF8StringEncoding error: &theError];
		if( !code )
		{
			NSLog( @"Couldn't load file '%@.cikernel': %@", kernelName, theError );
			[self autorelease];
			return nil;
		}
        NSArray     *kernels = [CIKernel kernelsWithString: code];
 
        foundKernel = [kernels objectAtIndex: 0];
		[sFilterKernels setObject: foundKernel forKey: kernelName];
    }
 
    self = [super init];
	if( self )
	{
		inputTime = [[NSNumber numberWithDouble: 0.5] retain];
		filterKernel = [foundKernel retain];
	}
		
	return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(inputImage);
	DESTROY_DEALLOC(inputTargetImage);
	DESTROY_DEALLOC(inputTime);
	DESTROY_DEALLOC(filterKernel);
	
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

    return [self apply: filterKernel, src, target, inputTime, kCIApplyOptionDefinition, [src definition], nil];
}


-(instancetype) copyWithZone:(NSZone *)zone
{
	WILDTransitionFilter	*	tf = [super copyWithZone: zone];
	tf->inputImage = [inputImage retain];
	tf->inputTargetImage = [inputTargetImage retain];
	tf->inputTime = [inputTime retain];
	tf->filterKernel = [filterKernel retain];
	
	return tf;
}

@end
