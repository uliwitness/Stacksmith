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
#import "WILDDocument.h"


@interface WILDLayoutManager : NSLayoutManager
{
	
}



@end



@implementation WILDLayoutManager

-(void)	drawLinesUnderLinesForRectArray: (NSRectArray)rectArray count: (NSUInteger)rectCount forCharacterRange: (NSRange)charRange
{
	for( NSUInteger x = 0; x < rectCount; x++ )
	{
		[[NSColor darkGrayColor] set];
		[NSBezierPath strokeLineFromPoint: NSMakePoint(NSMinX(rectArray[x]), NSMaxY(rectArray[x])) toPoint: NSMakePoint(NSMaxX(rectArray[x]), NSMaxY(rectArray[x]))];
	}
}


- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
{
	NSTextContainer		*	tc = [self textContainerForGlyphAtIndex: glyphsToShow.location effectiveRange: NULL];
	NSUInteger				numRects = 0;
	
	NSRectArray	rects = [self rectArrayForGlyphRange: glyphsToShow withinSelectedGlyphRange: NSMakeRange(NSNotFound,0) inTextContainer: tc rectCount: &numRects];
	
	[self drawLinesUnderLinesForRectArray: rects count: numRects forCharacterRange: glyphsToShow];
	
	[super drawGlyphsForGlyphRange: glyphsToShow atPoint: origin];
}

@end



@implementation WILDTextView

@synthesize representedPart = mPart;

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
#if USE_CUSTOM_LAYOUT_MANAGER
		WILDLayoutManager	*	wlm = [[[WILDLayoutManager alloc] init] autorelease];
		NSTextContainer		*	tc = [[[NSTextContainer alloc] initWithContainerSize: NSMakeSize(frameRect.size.width,CGFLOAT_MAX)] autorelease];
		
		[self replaceTextContainer: tc];
		[[self textContainer] replaceLayoutManager: wlm];
#endif //USE_CUSTOM_LAYOUT_MANAGER
	}
	
	return self;
}


// Apparently NSTextView doesn't do fancy new stuff like cursor rects and instead
//	re-sets the cursor on mouse-moves:
-(void)	mouseMoved: (NSEvent*)event
{
	WILDTool		currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*		currCursor = [WILDTools cursorForTool: currTool];
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

