//
//  WILDTextView.m
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDTextView.h"
#import "WILDPart.h"
#import "WILDStack.h"
#import "WILDPartView.h"


@implementation WILDTextView

@synthesize representedPart = mPart;

// Apparently NSTextView doesn't do fancy new stuff like cursor rects and instead
//	re-sets the cursor on mouse-moves:
-(void)	mouseMoved: (NSEvent*)event
{
	WILDTool	currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( !currCursor )
		currCursor = [[[mPart stack] document] cursorWithID: 128];
	
	if( [self isEditable] && currTool == WILDBrowseTool )
		[super mouseMoved: event];
	else
		[currCursor set];
}


-(void)	mouseDown: (NSEvent*)evt
{
	if( ![self isEditable] && ![self isSelectable] )
		[[self window] makeFirstResponder: [self superview]];
	else
		[super mouseDown: evt];
}

@end
