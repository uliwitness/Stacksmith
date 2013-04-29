//
//  WILDDrawAddColorBezel.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDDrawAddColorBezel.h"


void	WILDDrawAddColorBezel( NSBezierPath* inShape, NSColor* inBodyColor,
										NSInteger bezelSize,
							  			CGFloat inAngle,
										NSColor* inHighlightColor,	// May be NIL.
										NSColor* inShadeColor )		// May be NIL.
{
	[NSGraphicsContext saveGraphicsState];
	
	if( bezelSize > 0 )
	{
		NSColor			*	highlightColor = inHighlightColor;
		NSColor			*	shadeColor = inShadeColor;
		
		if( !shadeColor )
			shadeColor = [inBodyColor blendedColorWithFraction: 0.4 ofColor: [NSColor blackColor]];
		
		if( !highlightColor )
			highlightColor = [inBodyColor blendedColorWithFraction: 0.4 ofColor: [NSColor whiteColor]];

		NSSize				shapeSize = inShape.bounds.size;
		NSSize				scaleFactor = { (shapeSize.width -bezelSize) / shapeSize.width, (shapeSize.height -bezelSize) / shapeSize.height };
		NSGradient*			theGradient = [[[NSGradient alloc] initWithStartingColor: highlightColor endingColor: shadeColor] autorelease];
		NSBezierPath*		shiftedPath = [[inShape copy] autorelease];
		NSAffineTransform*	trans = [NSAffineTransform transform];
		[trans translateXBy: (shapeSize.width -(shapeSize.width * scaleFactor.width)) / 2.0 yBy: (shapeSize.height -(shapeSize.height * scaleFactor.height)) / 2.0];
		[trans scaleXBy: scaleFactor.width yBy: scaleFactor.height];
		[shiftedPath transformUsingAffineTransform: trans];
		
		[theGradient drawInBezierPath: inShape angle: inAngle];
		[inBodyColor set];
		[shiftedPath fill];
	}
	else
	{
		[inBodyColor set];
		[inShape fill];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}


