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


NSImage*	WILDInvertedImage( NSImage* img );


NSImage*	WILDInvertedImage( NSImage* img )
{
	NSRect		iBox = NSZeroRect;
	iBox.size = [img size];
	NSImage*	hImg = [[[NSImage alloc] initWithSize: iBox.size] autorelease];
	[hImg lockFocus];
		CGContextRef    theCtx = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState( theCtx );
		[img drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];

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

-(void)	dealloc
{
	DESTROY_DEALLOC(lineColor);
	
	[super dealloc];
}


-(void)	drawWithFrame: (NSRect)origCellFrame inView: (NSView *)controlView
{
	//NSLog( @"state = %s", ([self state] == NSOnState) ? "on" : "off" );
	BOOL			isHighlighted = [self isHighlighted] || [self state] == NSOnState;
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
	if( [highlightColor isEqualTo: self.backgroundColor] )
		highlightColor = [self.backgroundColor blendedColorWithFraction: 0.3 ofColor: [NSColor blackColor]];
	NSColor	*	disabledColor = [lineColor blendedColorWithFraction: 0.5 ofColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: lineColor.alphaComponent]];
	
	[lineColor set];
	
	BOOL	isActive = [[controlView window] isKeyWindow] && [self isEnabled];
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
	
	if( [self bezelStyle] == NSRoundedBezelStyle )
	{
		CGFloat	cornerRoundness = drawAsDefault ? 7.0 : 8.0;
		buttonShape = [NSBezierPath bezierPathWithRoundedRect: cellFrame xRadius: cornerRoundness yRadius: cornerRoundness];
		buttonStrokeShape = [NSBezierPath bezierPathWithRoundedRect: clampedCellFrame xRadius: cornerRoundness yRadius: cornerRoundness];
	}
	else if( [self bezelStyle] == NSCircularBezelStyle )
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
		#if TRANSPARENT_BUTTONS_INVERT
		if( isHighlighted && ![self backgroundColor] && [self image] == nil )
			[[NSColor whiteColor] set];
		else
		#endif
		if( isHighlighted && isActive )
			[highlightColor set];
		else if( isHighlighted && !isActive )
			[disabledColor set];
		else
			[[self backgroundColor] set];
		
		[buttonShape fill];
	}
	
	if( [self isBordered] )
	{
		if( isActive )
			[lineColor set];
		else
			[disabledColor set];
		[buttonStrokeShape stroke];
	}
	
	[NSGraphicsContext saveGraphicsState];
	//[buttonShape setClip];
	NSRect				imgBox = origCellFrame;
	imgBox.origin.x = imgBox.origin.x +truncf((origCellFrame.size.width -[self image].size.width) /2);
	imgBox.origin.y = imgBox.origin.y +truncf((origCellFrame.size.height -[self image].size.height) /2);
	imgBox.size = [self image].size;
	
	NSAttributedString*	attrTitle = [self attributedTitle];
	NSSize		textExtents = [attrTitle size];
	NSRect		txBox = origCellFrame;
	CGFloat		xHalf = truncf((origCellFrame.size.width -textExtents.width) /2);
	CGFloat		yHalf = truncf((origCellFrame.size.height -textExtents.height) /2);
	txBox.origin.x = txBox.origin.x +xHalf;
	txBox.origin.y = txBox.origin.y +yHalf;
	txBox.size = textExtents;
		
	BOOL		iconHighlight = isHighlighted && [self image];
	if( iconHighlight )
	{
		NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
		
		txBox.size.width += 4;
		txBox.origin.x -= 2;
		
		[muAttrTitle addAttribute: NSForegroundColorAttributeName value: [self backgroundColor]
						range: NSMakeRange(0,[muAttrTitle length])];
		attrTitle = muAttrTitle;
	}
	else if( isHighlighted )
	{
		if( highlightColor == self.lineColor )	// We didn't have to generate highlight cuz line & bg are same?
		{
			NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
			
			[muAttrTitle addAttribute: NSForegroundColorAttributeName value: [self backgroundColor]
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
	
	CGContextRef	theContext = [[NSGraphicsContext currentContext] graphicsPort];
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


-(NSUInteger)	hitTestForEvent: (NSEvent *)event inRect: (NSRect)cellFrame ofView: (NSView *)controlView
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
