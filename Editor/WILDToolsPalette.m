//
//  WILDToolsPalette.m
//  Stacksmith
//
//  Created by Uli Kusterer on 11.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDToolsPalette.h"
#import "WILDTools.h"
#import "UKHelperMacros.h"


@implementation WILDToolsPalette

static WILDToolsPalette*	sSharedToolsPalette = nil;

@synthesize lineColorWell = mLineColorWell;
@synthesize fillColorWell = mFillColorWell;

+(WILDToolsPalette*)	sharedToolsPalette
{
	if( !sSharedToolsPalette )
	{
		sSharedToolsPalette = [[WILDToolsPalette alloc] init];
		[sSharedToolsPalette window];
	}
	
	return sSharedToolsPalette;
}

- (id)init
{
    self = [super initWithWindowNibName: NSStringFromClass([self class])];
    if (self)
	{
        sSharedToolsPalette = self;
    }
    
    return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(mLineColorWell);
	DESTROY_DEALLOC(mFillColorWell);
	
    [super dealloc];
}

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	[[self window] setLevel: NSFloatingWindowLevel];
    
	ULIPaintView	* cpv = [ULIPaintView currentPaintView];
	if( cpv )
	{
		[mLineColorWell setColor: [cpv lineColor]];
		[mFillColorWell setColor: [cpv fillColor]];
	}
}

-(void)	orderFrontToolsPalette: (id)sender
{
	ULIPaintView	* cpv = [ULIPaintView currentPaintView];
	if( cpv )
	{
		[mLineColorWell setColor: [cpv lineColor]];
		[mFillColorWell setColor: [cpv fillColor]];
	}
	else
	{
		[mLineColorWell setColor: [NSColor blackColor]];
		[mFillColorWell setColor: [NSColor clearColor]];
	}
	
	[[self window] orderFront: sender];
}

-(NSColor*)	lineColor
{
	return [mLineColorWell color];
}


-(NSColor*)	fillColor
{
	return [mFillColorWell color];
}


-(IBAction)	takeLineColorFrom: (NSColorWell*)sender
{
	[[ULIPaintView currentPaintView] takeLineColorFrom: sender];
}


-(IBAction)	takeFillColorFrom: (NSColorWell*)sender
{
	[[ULIPaintView currentPaintView] takeFillColorFrom: sender];
}

@end
