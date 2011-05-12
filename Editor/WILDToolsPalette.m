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

@synthesize lineColorWell = mLineColorWell;
@synthesize fillColorWell = mFillColorWell;

+(WILDToolsPalette*)	sharedToolsPalette
{
	static WILDToolsPalette*	sSharedToolsPalette = nil;
	if( !sSharedToolsPalette )
	{
		sSharedToolsPalette = [[WILDToolsPalette alloc] initWithWindowNibName: NSStringFromClass(self)];
		[sSharedToolsPalette window];
	}
	
	return sSharedToolsPalette;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
	{
        // Initialization code here.
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
	
	[[self window] makeKeyAndOrderFront: sender];
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
