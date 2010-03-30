//
//  UKPropagandaButtonCell.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaButtonCell.h"
#import <QuartzCore/QuartzCore.h>
#import <Carbon/Carbon.h>


NSImage*	UKPropagandaInvertedImage( NSImage* img )
{
	NSRect		iBox = NSZeroRect;
	iBox.size = [img size];
	NSImage*	hImg = [[[NSImage alloc] initWithSize: iBox.size] autorelease];
	[hImg lockFocus];
		CGContextRef    theCtx = [[NSGraphicsContext currentContext] graphicsPort];
		[img drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];

		// Make sure we only touch opaque pixels:
		CGContextClipToMask( theCtx, NSRectToCGRect(iBox), [img CGImageForProposedRect: nil context: [NSGraphicsContext currentContext] hints: nil] );

		// Now draw a rectangle over the icon that flips all the pixels:
		CGContextSetBlendMode( theCtx, kCGBlendModeDifference );
		CGContextSetRGBFillColor( theCtx, 1, 1, 1, 1.0 );
		CGContextFillRect( theCtx, NSRectToCGRect( iBox ) );
		CGContextSetBlendMode( theCtx, kCGBlendModeNormal );
	[hImg unlockFocus];
	return hImg;
}


@implementation UKPropagandaButtonCell

@synthesize drawAsDefault;

-(void)	drawWithFrame: (NSRect)origCellFrame inView: (NSView *)controlView
{
	[[NSColor blackColor] set];
	
	NSRect			cellFrame = origCellFrame;
	NSBezierPath*	buttonShape = nil;
	NSBezierPath*	buttonStrokeShape = nil;
	NSRect			clampedCellFrame = cellFrame;
	clampedCellFrame.origin.x = truncf(clampedCellFrame.origin.x) +0.5;
	clampedCellFrame.origin.y = truncf(clampedCellFrame.origin.y) +0.5;
	clampedCellFrame.size.width -= 1;
	clampedCellFrame.size.height -= 1;
	
	BOOL	isActive = [[controlView window] isKeyWindow];
	if( drawAsDefault )
	{
		[NSBezierPath setDefaultLineWidth: 3];
		if( isActive )
			[[NSColor blackColor] set];
		else
			[[NSColor grayColor] set];
		[[NSBezierPath bezierPathWithRoundedRect: NSInsetRect(clampedCellFrame, 1, 1) xRadius: 8 yRadius: 8] stroke];
		[NSBezierPath setDefaultLineWidth: 1];
		if( !isActive )
			[[NSColor blackColor] set];
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
		|| ([self isHighlighted] && [self image] == nil) )
	{
		if( [self isHighlighted] )
			[[NSColor blackColor] set];
		else
			[[self backgroundColor] set];
		
		[buttonShape fill];
	}
	
	if( [self isBordered] )
	{
		[[NSColor blackColor] set];
		[buttonStrokeShape stroke];
	}
	
	[NSGraphicsContext saveGraphicsState];
	[buttonShape setClip];
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
		
	BOOL		iconHighlight = [self isHighlighted] && [self image];
	if( iconHighlight )
	{
		NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
		
		txBox.size.width += 4;
		txBox.origin.x -= 2;
		
		[muAttrTitle addAttribute: NSForegroundColorAttributeName value: [NSColor whiteColor]
						range: NSMakeRange(0,[muAttrTitle length])];
		attrTitle = muAttrTitle;
	}
	else if( [self isHighlighted] )
	{
		NSMutableAttributedString*	muAttrTitle = [[attrTitle mutableCopy] autorelease];
		
		[muAttrTitle addAttribute: NSForegroundColorAttributeName value: [NSColor whiteColor]
						range: NSMakeRange(0,[muAttrTitle length])];
		attrTitle = muAttrTitle;
	}
	
	CGContextRef	theContext = [[NSGraphicsContext currentContext] graphicsPort];
	if( [self image] != nil && [self imagePosition] == NSImageAbove )
	{
		txBox.origin.y += truncf([self image].size.height /2);
		imgBox.origin.y -= truncf(textExtents.height /2);
		
		if( [self isHighlighted] )
			[[NSColor blackColor] set];
		else
			[[NSColor whiteColor] set];
		[NSBezierPath fillRect: txBox];
		
		NSImage*		img = [self isHighlighted] ? UKPropagandaInvertedImage([self image]) : [self image];
		CGImageRef		theCGImage = [img CGImageForProposedRect: nil
											context: [NSGraphicsContext currentContext] hints: nil];
		HIViewDrawCGImage( theContext, (HIRect*)&imgBox, theCGImage );
	}
	else if( [self image] != nil && [self imagePosition] == NSImageOnly )
	{
		CGContextRef	theContext = [[NSGraphicsContext currentContext] graphicsPort];
		NSImage*		img = [self isHighlighted] ? UKPropagandaInvertedImage([self image]) : [self image];
		CGImageRef		theCGImage = [img CGImageForProposedRect: nil
											context: [NSGraphicsContext currentContext] hints: nil];
		HIViewDrawCGImage( theContext, (HIRect*)&imgBox, theCGImage );
	}
	
	if( [self imagePosition] != NSImageOnly )
		[attrTitle drawInRect: txBox];
	[NSGraphicsContext restoreGraphicsState];
}

@end
