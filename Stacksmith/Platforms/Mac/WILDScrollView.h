//
//  WILDScrollView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDScrollView : NSScrollView
{
	NSColor			*	lineColor;
	CGFloat				lineWidth;
}

@property (retain) NSColor		*	lineColor;
@property (assign) CGFloat			lineWidth;

@end
