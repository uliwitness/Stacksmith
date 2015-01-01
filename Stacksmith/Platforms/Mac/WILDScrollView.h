//
//  WILDScrollView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "CPart.h"


@interface WILDScrollView : NSScrollView
{
	NSColor			*	lineColor;
	CGFloat				lineWidth;
	NSTrackingArea	*	mCursorTrackingArea;
	Carlson::CPart	*	owningPart;
}

@property (retain,nonatomic) NSColor		*	lineColor;
@property (assign,nonatomic) CGFloat			lineWidth;
@property (assign,nonatomic) Carlson::CPart	*	owningPart;

@end
