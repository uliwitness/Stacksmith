//
//  WILDButtonCell.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDButtonCell.h"
#import <QuartzCore/QuartzCore.h>
#import <Carbon/Carbon.h>
#import "UKGraphics.h"
#import "UKHelperMacros.h"
#import "WILDDrawAddColorBezel.h"
#import "NSImage+NiceScaling.h"


#if MAC_OS_X_VERSION_MAX_ALLOWED == MAC_OS_X_VERSION_10_9
typedef NSUInteger NSCellHitResult;
#endif


NSImage*	WILDInvertedImage( NSImage* img );


NSImage*	WILDInvertedImage( NSImage* img )
{
	NSRect		iBox = NSZeroRect;
	iBox.size = [img size];
	NSImage*	hImg = [[[NSImage alloc] initWithSize: iBox.size] autorelease];
	[hImg lockFocus];
		CGContextRef    theCtx = [[NSGraphicsContext currentContext] CGContext];
		CGContextSaveGState( theCtx );
		[img drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositingOperationCopy fraction: 1.0];

		// Make sure we only touch opaque pixels:
		CGContextClipToMask( theCtx, NSRectToCGRect(iBox), [img CGImageForProposedRect: nil context: [NSGraphicsContext currentContext] hints: nil] );

		// Now draw a rectangle over the icon that flips all the pixels:
		CGContextSetBlendMode( theCtx, kCGBlendModeDifference );
		CGContextSetRGBFillColor( theCtx, 1, 1, 1, 1.0 );
		CGContextFillRect( theCtx, NSRectToCGRect( iBox ) );
		CGContextSetBlendMode( theCtx, kCGBlendModeNormal );
		CGContextRestoreGState( theCtx );
	[hImg unlockFocus];
	return hImg;
}


@implementation WILDButtonCell

@synthesize drawAsDefault;
@synthesize lineColor;
@synthesize lineWidth;
@synthesize bevelWidth;
@synthesize bevelAngle;
@synthesize ignoreInactiveAppearance;

-(void)	dealloc
{
	DESTROY_DEALLOC(lineColor);
	
	[super dealloc];
}


-(void)	drawWithFrame: (NSRect)origCellFrame inView: (NSView *)controlView
{
	//NSLog( @"state = %s", ([self state] == NSControlStateValueOn) ? "on" : "off" );
	BOOL			isHighlighted = [self isHighlighted] || [self state] == NSControlStateValueOn;
	NSRect			cellFrame = origCellFrame;
	NSBezierPath*	buttonShape = nil;
	NSBezierPath*	buttonStrokeShape = nil;
	NSRect			clampedCellFrame = cellFrame;
	clampedCellFrame.origin.x = truncf(clampedCellFrame.origin.x) +0.5;
	clampedCellFrame.origin.y = truncf(clampedCellFrame.origin.y) +0.5;
	clampedCellFrame.size.width -= 1;
	clampedCellFrame.size.height -= 1;
	
	if( !lineColor )
		lineColor = [[NSColor blackColor] retain];
	NSColor		*	highlightColor = lineColor;
	if( [highlightColor isEqual: self.backgroundColor] )
		highlightColor = [self.backgroundColor blendedColorWithFraction: 0.3 ofColor: [NSColor blackColor]];
	NSColor	*	disabledColor = [lineColor blendedColorWithFraction: 0.5 ofColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: lineColor.alphaComponent]];
	
	[lineColor set];
	
	BOOL	isActive = ([[controlView window] isKeyWindow] || ignoreInactiveAppearance) && [self isEnabled];
	if( drawAsDefault )
	{
		[NSBezierPath setDefaultLineWidth: 3];
		if( isActive )
			[lineColor set];
		else
			[disabledColor set];
		[[NSBezierPath bezierPathWithRoundedRect: NSInsetRect(clampedCellFrame, 1, 1) xRadius: 8 yRadius: 8] stroke];
		[NSBezierPath setDefaultLineWidth: 1];
		if( !isActive )
			[lineColor set];
		cellFrame = NSInsetRect( cellFrame, 4, 4 );
		clampedCellFrame = NSInsetRect( clampedCellFrame, 4, 4 );
	}
	
	cellFrame = NSInsetRect( cellFrame, ceilf(lineWidth /2), ceilf(lineWidth /2) );
	clampedCellFrame = NSInsetRect( clampedCellFrame, ceilf(lineWidth /2), ceilf(lineWidth /2) );
	
	if( [self bezelStyle] == NSBezelStyleRounded )
	{
		CGFloat	cornerRoundness = drawAsDefault ? 7.0 : 8.0;
		buttonShape = [NSBezierPath bezierPathWithRoundedRect: cellFrame xRadius: cornerRoundness yRadius: cornerRoundness];
		buttonStrokeShape = [NSBezierPath bezierPathWithRoundedRect: clampedCellFrame xRadius: cornerRoundness yRadius: cornerRoundness];
	}
	else if( [self bezelStyle] == NSBezelStyleCircular )
	{
		buttonShape = [NSBezierPath bezierPathWithOvalInRect: cellFrame];
		buttonStrokeShape = [NSBezierPath bezierPathWithOvalInRect: clampedCellFrame];
	}
	else
	{
		buttonShape = [NSBezierPath bezierPathWithRect: cellFrame];
		buttonStrokeShape = [NSBezierPath bezierPathWithRect: clampedCellFrame];
	}

	if( [self backgroundColor]
		|| (isHighlighted && [self image] == nil) )
	{
		NSColor	*	bgColor = nil;
		#if TRANSPARENT_BUTTONS_INVERT
		if( isHighlighted && ![self backgroundColor] && [self image] == nil )
			bgColor = [NSColor whiteColor];
		else
		#endif
		if( isHighlighted && isActive )
			bgColor = highlightColor;
		else if( isHighlighted && !isActive )
			bgColor = disabledColor;
		else
			bgColor = self.backgroundColor;
		
		if( self.bevelWidth == 0 && bgColor )
		{
			[bgColor set];
			[buttonShape fill];
		}
		else if( bgColor )
			WILDDrawAddColorBezel( buttonShape, bgColor, self.bevelWidth, self.bevelAngle, nil, nil );
	}
	
	if( [self isBordered] && lineWidth > 0 )
	{
		if( isActive )
			[lineColor set];
		else
			[disabledColor set];
		[buttonStrokeShape setLineWidth: lineWidth];
		[buttonStrokeShape stroke];
	}
	
	[NSGraphicsContext saveGraphicsState];
	[buttonShape addClip];

	NSAttributedString*	attrTitle = [self attributedTitle];
	NSSize		textExtents = [attrTitle size];
	NSRect		txBox = origCellFrame;
	CGFloat		xHalf = truncf((origCellFrame.size.width -textExtents.width) /2);
	CGFloat		yHalf = truncf((origCellFrame.size.height -textExtents.height) /2);
	txBox.origin.x = txBox.origin.x +xHalf;
	txBox.origin.y = txBox.origin.y +yHalf;
	txBox.size = textExtents;
		
	NSRect				imgBox = origCellFrame;
	imgBox.origin.x = imgBox.origin.x +truncf((origCellFrame.size.width -[self image].size.width) /2);
	imgBox.origin.y = imgBox.origin.y +truncf((origCellFrame.size.height -[self image].size.height) /2);
	imgBox.size = [self image].size;
	
	if( self.imageScaling == NSImageScaleProportionallyDown )
	{
		NSSize imgAvailable = origCellFrame.size;
		if( [self imagePosition] != NSImageOnly )
		{
			imgAvailable.height -= txBox.size.height;
		}
		if( imgAvailable.width < imgBox.size.width )
		{
			imgBox.size = [NSImage scaledSize:imgBox.size toFitSize:imgAvailable];
			imgBox.origin.x = origCellFrame.origin.x +truncf((origCellFrame.size.width -imgBox.size.width) /2);
			imgBox.origin.y = origCellFrame.origin.y +truncf((origCellFrame.size.height -imgBox.size.height) /2);
		}
	}
	
	BOOL		iconHighlight = isHighlighted && [self image];
	if( iconHighlight )
	{
		NSColor		*	bgColor = [self backgroundColor];
		if( bgColor )
		{
			NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
			
			txBox.size.width += 4;
			txBox.origin.x -= 2;
			
			[muAttrTitle addAttribute: NSForegroundColorAttributeName value: [self backgroundColor]
							range: NSMakeRange(0,[muAttrTitle length])];
			attrTitle = muAttrTitle;
		}
	}
	else if( isHighlighted )
	{
		if( highlightColor == self.lineColor )	// We didn't have to generate highlight cuz line & bg are same?
		{
			NSColor		*	bgColor = [self backgroundColor];
			if( !bgColor )
				bgColor = NSColor.whiteColor;
			NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
			
			[muAttrTitle addAttribute: NSForegroundColorAttributeName value: bgColor
							range: NSMakeRange(0,[muAttrTitle length])];
			attrTitle = muAttrTitle;
		}
	}
	else if( !isActive )
	{
		NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
		
		[muAttrTitle addAttribute: NSForegroundColorAttributeName value: disabledColor
						range: NSMakeRange(0,[muAttrTitle length])];
		attrTitle = muAttrTitle;
	}
	else
	{
		NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
		
		[muAttrTitle addAttribute: NSForegroundColorAttributeName value: lineColor
							range: NSMakeRange(0,[muAttrTitle length])];
		attrTitle = muAttrTitle;
	}
	
	CGContextRef	theContext = [[NSGraphicsContext currentContext] CGContext];
	//UKLog( @"%@ %ld", self, [self imagePosition] );
	if( [self image] != nil && [self imagePosition] == NSImageAbove )
	{
		txBox.origin.y += truncf([self image].size.height /2);
		imgBox.origin.y -= truncf(textExtents.height /2);
		
		if( isHighlighted && isActive )
			[lineColor set];
		else if( isHighlighted && !isActive )
			[disabledColor set];
		else
			[[self backgroundColor] set];
		[NSBezierPath fillRect: txBox];
		
		NSImage*		img = isHighlighted ? WILDInvertedImage([self image]) : [self image];
		CGImageRef		theCGImage = [img CGImageForProposedRect: nil
											context: [NSGraphicsContext currentContext] hints: nil];
		UKCGContextDrawImageFlipped( theContext, imgBox, theCGImage );
	}
	else if( [self image] != nil && [self imagePosition] == NSImageOnly )
	{
		NSImage*		img = isHighlighted ? WILDInvertedImage([self image]) : [self image];
		CGImageRef		theCGImage = [img CGImageForProposedRect: nil
											context: [NSGraphicsContext currentContext] hints: nil];
		UKCGContextDrawImageFlipped( theContext, imgBox, theCGImage );
	}
	
	if( [self imagePosition] != NSImageOnly )
		[attrTitle drawInRect: txBox];
	[NSGraphicsContext restoreGraphicsState];
}


-(void)	setImagePosition:(NSCellImagePosition)aPosition
{
	[super setImagePosition: aPosition];
	//UKLog( @"%@ %ld %ld", self, aPosition, self.imagePosition );
}


-(NSInteger)	nextState
{
	return [self state];
}


-(NSCellHitResult)	hitTestForEvent: (NSEvent *)event inRect: (NSRect)cellFrame ofView: (NSView *)controlView
{
	NSUInteger		hitPart = NSCellHitNone;
	NSPoint			mousePos = [controlView convertPoint: [event locationInWindow] fromView: nil];
	
	if( NSPointInRect( mousePos, cellFrame ) )
	{
		hitPart = NSCellHitContentArea | NSCellHitTrackableArea;
	}
	
	return hitPart;
}

@end
