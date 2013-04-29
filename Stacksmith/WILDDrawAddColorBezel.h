//
//  WILDDrawAddColorBezel.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


void	WILDDrawAddColorBezel( NSBezierPath* inShape, NSColor* inBodyColor,
										NSInteger bezelSize,
										CGFloat inAngle,
										NSColor* inHighlightColor,	// May be NIL.
										NSColor* inShadeColor );	// May be NIL.
