//
//  WILDButtonCell.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDButtonCell : NSButtonCell
{
	BOOL	drawAsDefault;	// Are we a default button? Can't check the shortcut, as HC doesn't auto-handle return key presses, so we'd interfere with stack code. Also, Cocoa only sets this shortcut on current default button, so buttons would revert to standard in the background.
	NSColor	*lineColor;
}

@property (assign) BOOL 	drawAsDefault;
@property (assign) BOOL 	ignoreInactiveAppearance;
@property (retain) NSColor*	lineColor;
@property (assign) CGFloat	lineWidth;
@property (assign) CGFloat	bevelWidth;
@property (assign) CGFloat	bevelAngle;

@end
