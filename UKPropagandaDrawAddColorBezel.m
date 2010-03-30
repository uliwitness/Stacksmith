//
//  UKPropagandaDrawAddColorBezel.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaDrawAddColorBezel.h"


void	UKPropagandaDrawAddColorBezel( NSBezierPath* inShape, NSColor* inBodyColor,
										NSInteger bezelSize,
										NSColor* inHighlightColor,	// May be NIL.
										NSColor* inShadeColor )	// May be NIL.
{
	[NSGraphicsContext saveGraphicsState];
	
	[inBodyColor set];
	[inShape fill];
	
	if( bezelSize > 1 )
	{
		NSColor			*	highlightColor = inHighlightColor;
		NSColor			*	shadeColor = inShadeColor;
		
		if( !shadeColor )
			shadeColor = [inBodyColor blendedColorWithFraction: 0.4 ofColor: [NSColor blackColor]];
		
		if( !highlightColor )
			highlightColor = [inBodyColor blendedColorWithFraction: 0.4 ofColor: [NSColor whiteColor]];
		
		NSBezierPath*		shiftedPath = [inShape bezierPathByReversingPath];
		NSAffineTransform*	trans = [NSAffineTransform transform];
		[trans translateXBy: bezelSize yBy: -bezelSize];
		[shiftedPath transformUsingAffineTransform: trans];
		[shiftedPath appendBezierPath: inShape];
		
		float		diagonalAngle = -45.0;	// +++ Calc actual angle
		
		[inShape addClip];
		NSGradient*	theGradient = [[[NSGradient alloc] initWithStartingColor: highlightColor endingColor: inBodyColor] autorelease];
		[theGradient drawInBezierPath: shiftedPath angle: diagonalAngle];
		
		trans = [NSAffineTransform transform];
		[trans translateXBy: -bezelSize yBy: bezelSize];
		[shiftedPath transformUsingAffineTransform: trans];
		theGradient = [[[NSGradient alloc] initWithStartingColor: inBodyColor endingColor: shadeColor] autorelease];
		[theGradient drawInBezierPath: shiftedPath angle: diagonalAngle];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}


