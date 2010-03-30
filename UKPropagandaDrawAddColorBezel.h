//
//  UKPropagandaDrawAddColorBezel.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


void	UKPropagandaDrawAddColorBezel( NSBezierPath* inShape, NSColor* inBodyColor,
										NSInteger bezelSize,
										NSColor* inHighlightColor,	// May be NIL.
										NSColor* inShadeColor );	// May be NIL.
