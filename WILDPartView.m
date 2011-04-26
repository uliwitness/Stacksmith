//
//  WILDSelectionView.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDPartView.h"
#import "WILDNotifications.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPart.h"
#import "WILDPartContents.h"
#import "WILDButtonInfoWindowController.h"
#import "WILDFieldInfoWindowController.h"
#import "WILDCardView.h"
#import "WILDClickablePopUpButtonLabel.h"
#import "WILDButtonCell.h"
#import "WILDTextView.h"
#import "UKIsDragStart.h"
#import "WILDPresentationConstants.h"
#import "WILDButtonView.h"
#import "WILDScrollView.h"
#import <QuartzCore/QuartzCore.h>


@class WILDCardView;


@implementation WILDPartView

@synthesize mainView = mMainView;
@synthesize helperView = mHelperView;

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		
	}
	return self;
}


-(void)	dealloc
{
	[[WILDTools sharedTools] removeClient: self];
	[self unsubscribeNotifications];
	
	[super dealloc];
}


-(void)	unsubscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
											object: nil];
}


-(void)	subscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partWillChange:)
											name: WILDPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:)
											name: WILDPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
											name: WILDCurrentToolDidChangeNotification
											object: nil];
}


-(void)	highlightSearchResultInRange: (NSRange)theRange
{
	[(NSTextView*)mMainView setSelectedRange: theRange];
	[(NSTextView*)mMainView scrollRangeToVisible: theRange];
	[(NSTextView*)mMainView showFindIndicatorForRange: theRange];
}


-(void)	animate: (id)sender
{
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


-(BOOL)	myToolIsCurrent
{
	BOOL	isMyTool = ([[WILDTools sharedTools] currentTool] == WILDButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[WILDTools sharedTools] currentTool] == WILDFieldTool && [[mPart partType] isEqualToString: @"field"]);
	return isMyTool;
}


-(void)	setSelected: (BOOL)inState
{
	if( mSelected != inState )
	{
		mSelected = inState;
		
		if( mSelected )
			[[WILDTools sharedTools] addClient: self];
		else
			[[WILDTools sharedTools] removeClient: self];
	}
}


-(BOOL)	isSelected
{
	return mSelected;
}


-(void)	drawSubView: (NSView*)subview dirtyRect: (NSRect)dirtyRect
{
	NSRect	subviewBounds = [subview bounds];
	BOOL	isMyTool = [self myToolIsCurrent];
	
	if( mSelected )
	{
		[[NSColor keyboardFocusIndicatorColor] set];
		NSRect	clampedBounds = subviewBounds;
		clampedBounds.origin.x = truncf(clampedBounds.origin.x) + 0.5;
		clampedBounds.origin.y = truncf(clampedBounds.origin.y) + 0.5;
		clampedBounds.size.width -= 1;
		clampedBounds.size.height -= 1;
		NSBezierPath*	selPath = [NSBezierPath bezierPathWithRect: clampedBounds];
		CGFloat			pattern[2] = { 4, 4 };
		[[NSColor whiteColor] set];
		[selPath stroke];
		[selPath setLineDash: pattern count: 2 phase: [[WILDTools sharedTools] animationPhase]];
		[[NSColor keyboardFocusIndicatorColor] set];
		[selPath stroke];
	}
	else if( isMyTool )
	{
		if( [[mPart style] isEqualToString: @"opaque"] )
			[[[WILDTools sharedTools] peekPattern] set];
		else
			[[NSColor grayColor] set];
		NSRect	peekBox = NSInsetRect( subviewBounds, 0.5, 0.5 );
		[NSBezierPath setDefaultLineWidth: 1];
		[NSBezierPath strokeRect: peekBox];
		[[NSColor blackColor] set];
	}
	
    if( mPeeking )
	{
		NSRect	peekBox = NSInsetRect( subviewBounds, 1, 1 );
		[NSBezierPath setDefaultLineWidth: 2];
		[[NSColor lightGrayColor] set];
		[[NSColor blueColor] set];
		[NSBezierPath strokeRect: peekBox];
		[[[WILDTools sharedTools] peekPattern] set];
		[NSBezierPath strokeRect: peekBox];
		[NSBezierPath setDefaultLineWidth: 1];
	}
}


-(NSView *)	hitTest: (NSPoint)aPoint	// Equivalent to Carbon kEventControlInterceptSubviewClick.
{
	BOOL	isMyTool = [self myToolIsCurrent];
	NSView*	hitView = [super hitTest: aPoint];
	if( hitView != nil )	// Was in our view or a sub view, not outside us?
	{
		if( mPeeking || isMyTool )
			hitView = self;		// Redirect to us.
		else if( [[WILDTools sharedTools] currentTool] != WILDBrowseTool )	// Another tool than the ones we support?
			hitView = nil;	// Pretend we (or our subviews) weren't hit at all.
		else if( [[WILDTools sharedTools] currentTool] == WILDBrowseTool && hitView == self )	// Browse tool but not in our subviews?
			hitView = nil;	// Pretend we weren't hit at all. Maybe a view under us does better.
	}
	
	return hitView;
}



-(WILDPartGrabHandle)	grabHandleAtPoint: (NSPoint)localPoint
{
	WILDPartGrabHandle		clickedHandle = 0;
	NSRect					myRect = self.bounds;
	CGSize					handleSize = { 8, 8 };
	
	if( (myRect.size.width /3) < handleSize.width )
		handleSize.width = truncf(myRect.size.width /3);
	if( (myRect.size.height /3) < handleSize.height )
		handleSize.height = truncf(myRect.size.height /3);
	
	if( NSPointInRect(localPoint, myRect ) )
	{
		if( NSMinX(myRect) <= localPoint.x && (NSMinX(myRect) +handleSize.width) >= localPoint.x )
			clickedHandle |= WILDPartGrabHandleLeft;
		if( NSMaxX(myRect) >= localPoint.x && (NSMaxX(myRect) -handleSize.width) <= localPoint.x )
			clickedHandle |= WILDPartGrabHandleRight;
		if( NSMinY(myRect) <= localPoint.y && (NSMinY(myRect) +handleSize.height) >= localPoint.y )
			clickedHandle |= WILDPartGrabHandleBottom;
		if( NSMaxY(myRect) >= localPoint.y && (NSMaxY(myRect) -handleSize.height) <= localPoint.y )
			clickedHandle |= WILDPartGrabHandleTop;
	}
	
	return clickedHandle;
}


-(void)	resizeViewUsingHandle: (WILDPartGrabHandle)inHandle
{
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	BOOL					keepDragging = YES;
	
	while( keepDragging )
	{
		NSEvent		*	theEvent = [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( theEvent )
		{
			switch( [theEvent type] )
			{
				case NSLeftMouseUp:
					keepDragging = NO;
					break;
				
				case NSLeftMouseDragged:
				{
					NSRect	newBox = [self frame];
					CGFloat	deltaX = [theEvent deltaX];
					CGFloat	deltaY = -[theEvent deltaY];
					
					if( inHandle & WILDPartGrabHandleLeft )
					{
						newBox.origin.x += deltaX;
						newBox.size.width -= deltaX;
					}
					else if( inHandle & WILDPartGrabHandleRight )
						newBox.size.width += deltaX;

					if( inHandle & WILDPartGrabHandleTop )
						newBox.size.height += deltaY;
					else if( inHandle & WILDPartGrabHandleBottom )
					{
						newBox.origin.y += deltaY;
						newBox.size.height -= deltaY;
					}
					
					[self setFrame: newBox];
					break;
				}
			}
		}
		
		[pool drain];
		pool = [[NSAutoreleasePool alloc] init];
	}

	[pool drain];
	
	[mPart setRectangle: NSInsetRect( self.frame, 2, 2)];
}


-(void)	mouseDown: (NSEvent*)event
{
	BOOL	isMyTool = [self myToolIsCurrent];
	if( mPeeking )
	{
		WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
		[sewc setGlobalStartRect: [self frameInScreenCoordinates]];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( isMyTool )
	{
		WILDPartGrabHandle	hitHandle = [self grabHandleAtPoint: [self convertPoint: [event locationInWindow] fromView: nil]];
		
		if( [event clickCount] == 2 && mSelected )
		{
			NSWindowController*	infoController = nil;
			if( [[mPart partType] isEqualToString: @"button"] )
				infoController = [[WILDButtonInfoWindowController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
			else
				infoController = [[WILDFieldInfoWindowController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];

			[[[[self window] windowController] document] addWindowController: infoController];
			[infoController showWindow: self];
		}
		else
		{
			BOOL		justSelected = NO;
			if( !mSelected )
			{
				[self selectionClick: event];
				justSelected = YES;
			}
			
			if( UKIsDragStart( event, 0.0 ) )
			{
				if( hitHandle == 0 )
				{
					NSPasteboard*   		pb = [NSPasteboard pasteboardWithName: NSDragPboard];
					[pb clearContents];
					NSPoint					dragStartImagePos = NSZeroPoint;
					NSArray*				selectedObjects = [[[WILDTools sharedTools] clients] allObjects];
					NSImage*				theDragImg = [[self class] imageForPeers: selectedObjects
															ofView: self
															dragStartImagePos: &dragStartImagePos];
					WILDCard*		currCard = [[self enclosingCardView] card];
					WILDBackground*	currBg = [currCard owningBackground];
					
					NSMutableString*		xmlString = [[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE parts PUBLIC \"-//Apple, Inc.//DTD stack V 2.0//EN\" \"\" >\n<parts>\n" mutableCopy] autorelease];
					for( WILDPartView* selView in selectedObjects )
					{
						WILDPart*	thePart = [selView part];
						[xmlString appendString: [thePart xmlString]];
						NSString*	cdXmlStr = [[currCard contentsForPart: thePart] xmlString];
						if( cdXmlStr )
							[xmlString appendString: cdXmlStr];
						NSString*	bgXmlStr = [[currBg contentsForPart: thePart] xmlString];
						if( bgXmlStr )
							[xmlString appendString: bgXmlStr];
					}
					[xmlString appendString: @"</parts>"];
	//				NSLog(@"xmlString = %@",xmlString);
					
					[pb addTypes: [NSArray arrayWithObject: WILDPartPboardType] owner: [self enclosingCardView]];
					[pb setString: xmlString forType: WILDPartPboardType];
					
					// Actually commence the drag:
					[self dragImage: theDragImg at: dragStartImagePos offset: NSMakeSize(0,0)
								event: event pasteboard: pb source: [self enclosingCardView] slideBack: YES];
				}
				else
				{
					[self resizeViewUsingHandle: hitHandle];
				}
			}
			else if( !justSelected )
			{
				[self selectionClick: event];
			}
		}
	}
	else
	{
		[[self window] makeFirstResponder: [self superview]];
		[super mouseDown: event];
	}
}


-(void)	selectionClick: (NSEvent*)event
{
	if( [event modifierFlags] & NSShiftKeyMask
		|| [event modifierFlags] & NSCommandKeyMask )
		[self setSelected: !mSelected];
	else
	{
		[[WILDTools sharedTools] deselectAllClients];
		[self setSelected: YES];
	}
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


+(NSImage*)	imageForPeers: (NSArray*)views ofView: (NSView*)inView dragStartImagePos: (NSPoint*)dragStartImagePos
{
	CGFloat		minX = LONG_MAX, maxX = LONG_MIN, minY = LONG_MAX, maxY = LONG_MIN;
	NSPoint		viewOrigin = inView ? [inView frame].origin : NSZeroPoint;
	
	for( NSView* theView in views )
	{
		NSRect		box = [theView frame];
		if( minX > NSMinX(box) )
			minX = NSMinX(box);
		if( maxX < NSMaxX(box) )
			maxX = NSMaxX(box);
		if( minY > NSMinY(box) )
			minY = NSMinY(box);
		if( maxY < NSMaxY(box) )
			maxY = NSMaxY(box);
	}
	
	NSImage*		theImage = [[[NSImage alloc] initWithSize: NSMakeSize( maxX -minX, maxY -minY)] autorelease];
	
	[theImage lockFocus];
	CGContextRef		currContext = [[NSGraphicsContext currentContext] graphicsPort];

	[[NSColor redColor] set];
	
	for( WILDPartView* theView in views )
	{
		[NSGraphicsContext saveGraphicsState];
		
		CALayer*	theLayer = [theView layer];
		NSRect		layerFrame = [theLayer frame];
		
		layerFrame.origin.x -= minX;
		layerFrame.origin.y -= minY;
		
		NSAffineTransform*	transform = [NSAffineTransform transform];
		[transform translateXBy: layerFrame.origin.x yBy: layerFrame.origin.y];
		[transform concat];
		
		BOOL	wasSelected = theView->mSelected;
		theView->mSelected = NO;
		[theView display];
		[[theView mainView] display];
		[[theView helperView] display];
		[theLayer renderInContext: currContext];
		theView->mSelected = wasSelected;
		
		[NSGraphicsContext restoreGraphicsState];
	}
	[theImage unlockFocus];
	
	dragStartImagePos->x = -viewOrigin.x +minX;
	dragStartImagePos->y = -viewOrigin.y +minY;
	
	return theImage;
}


+(NSRect)	rectForPeers: (NSArray*)parts dragStartImagePos: (NSPoint*)dragStartImagePos
{
	CGFloat		minX = LONG_MAX, maxX = LONG_MIN, minY = LONG_MAX, maxY = LONG_MIN;
	NSPoint		viewOrigin = NSZeroPoint;
	
	for( WILDPart* thePart in parts )
	{
		NSRect		box = [thePart flippedRectangle];
		if( minX > NSMinX(box) )
			minX = NSMinX(box);
		if( maxX < NSMaxX(box) )
			maxX = NSMaxX(box);
		if( minY > NSMinY(box) )
			minY = NSMinY(box);
		if( maxY < NSMaxY(box) )
			maxY = NSMaxY(box);
	}
		
	dragStartImagePos->x = -viewOrigin.x +minX;
	dragStartImagePos->y = -viewOrigin.y +minY;
	
	return NSMakeRect(minX, minY, maxX -minX, maxY -minY);
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


-(void)	textDidChange: (NSNotification *)notification
{
	WILDPartContents	*	contents = [self currentPartContentsAndBackgroundContents: nil create: YES];
	
	[contents setStyledText: [mMainView textStorage]];
	
	[mPart updateChangeCount: NSChangeDone];
}


-(void)	setPart: (WILDPart*)inPart
{
	if( inPart == nil )
		[self unsubscribeNotifications];
	
	mPart = inPart;
	
	if( mPart != nil )
		[self subscribeNotifications];
}


-(WILDPart*)	part
{
	return mPart;
}


-(WILDCardView*)	enclosingCardView
{
	WILDCardView*		mySuper = (WILDCardView*) [self superview];
	if( mySuper && [mySuper isKindOfClass: [WILDCardView class]] )
		return mySuper;
	else
		return nil;
}

-(void)	partWillChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyWillChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
}


-(void)	partDidChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyDidChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
	else	// Unknown property. Reload the whole thing.
	{
		[self setFrame: NSInsetRect([mPart rectangle], -2, -2)];
		[self unloadPart];
		[self loadPart: mPart forBackgroundEditing: NO];
	}
}


-(void)	highlightedPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setState:)] )
		[(NSButton*)mMainView setState: [mPart highlighted] ? NSOnState : NSOffState];
}


-(void)	visiblePropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setHidden:)] )
		[self setHidden: ![mPart visible]];
}


-(void)	enabledPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setEnabled:)] )
		[(NSButton*)mMainView setEnabled: [mPart isEnabled]];
}


-(void)	iconPropertyDidChangeOfPart: (WILDPart*)inPart
{
	if( [mMainView respondsToSelector: @selector(setImage:)] )
		[(NSButton*)mMainView setImage: [mPart iconImage]];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[self setSelected: NO];
	[self setNeedsDisplay: YES];
	[mMainView setNeedsDisplay: YES];
	[mHelperView setNeedsDisplay: YES];
}


-(void)	unloadPart
{
	NSArray*	subviews = [[[self subviews] copy] autorelease];
	for( NSView* currView in subviews )
		[currView removeFromSuperview];
	[self setMainView: nil];
	[self setHelperView: nil];
	[self unsubscribeNotifications];
}


-(void)	updateOnClick: (NSButton*)sender
{
	WILDCardView*		winView = [self enclosingCardView];
	WILDCard*			theCd = [winView card];
	WILDBackground*		theBg = [theCd owningBackground];

	[mPart updateViewOnClick: sender withCard: theCd background: theBg];
}


-(void)	loadPopupButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect			partRect = [currPart rectangle];
	NSTextField*	label = nil;
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	NSRect		popupBox = partRect;
	if( [currPart titleWidth] > 0 )
	{
		NSRect	titleBox = popupBox;
		titleBox.size.width = [currPart titleWidth];
		popupBox.origin.x += titleBox.size.width;
		popupBox.size.width -= titleBox.size.width;
		
		label = [[WILDClickablePopUpButtonLabel alloc] initWithFrame: titleBox];
		[label setWantsLayer: YES];
		[label setEditable: NO];
		[label setSelectable: NO];
		[label setDrawsBackground: NO];
		[label setBezeled: NO];
		[label setBordered: NO];
		[[label cell] setWraps: NO];
		if( [currPart showName] )
			[label setStringValue: [currPart name]];
		[label setFont: [currPart textFont]];
		[label sizeToFit];
		titleBox.origin.y -= truncf((titleBox.size.height -[label bounds].size.height) /2);
		[label setFrame: titleBox];
		
		[self addSubview: label];
		[label setAutoresizingMask: NSViewMinYMargin | NSViewMaxYMargin];
		
		[self setHelperView: label];
	}
	
	NSPopUpButton	*	bt = [[NSPopUpButton alloc] initWithFrame: popupBox];
	[bt setWantsLayer: YES];
	[bt setFont: [currPart textFont]];
	[bt setTarget: self];
	[bt setAction: @selector(updateOnClick:)];
	
	NSArray*	popupItems = ([contents text] != nil) ? [contents listItems] : [bgContents listItems];
	for( NSString* itemName in popupItems )
	{
		if( [itemName hasPrefix: @"-"] )
			[[bt menu] addItem: [NSMenuItem separatorItem]];
		else
			[bt addItemWithTitle: itemName];
	}
	NSUInteger selIndex = [[currPart selectedListItemIndexes] firstIndex];
	if( selIndex == NSNotFound )
		selIndex = 0;
	[bt selectItemAtIndex: selIndex];
	[bt setState: [currPart highlighted] ? NSOnState : NSOffState];
	
	if( [self helperView] )
		[(WILDClickablePopUpButtonLabel*)[self helperView] setPopUpButton: bt];
	
	[self addSubview: bt];
	[bt setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[self setMainView: bt];
	
	if( label )
		[[bt cell] accessibilitySetOverrideValue: [label cell] forAttribute: NSAccessibilityTitleUIElementAttribute];
	
	[bt release];
}


-(void)	loadPushButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	BOOL		isHighlighted = [currPart highlighted];
	if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
		isHighlighted = [contents highlighted];
	
	BOOL			canHaveIcon = YES;
	NSButton	*	bt = [[WILDButtonView alloc] initWithFrame: partRect];
	[bt setWantsLayer: YES];
	
	if( [[currPart style] isEqualToString: @"transparent"]
		|| [[currPart style] isEqualToString: @"oval"] )
	{
		[bt setCell: [[[WILDButtonCell alloc] initTextCell: @""] autorelease]];
		[bt setBordered: NO];

		if( [[currPart style] isEqualToString: @"oval"] )
			[bt setBezelStyle: NSCircularBezelStyle];
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSMomentaryPushInButton];
		
#if TRANSPARENT_BUTTONS_INVERT
		if( isHighlighted )
		{
			CALayer*	theLayer = [self layer];
			[theLayer setOpaque: NO];
			CIFilter*	theFilter = [CIFilter filterWithName: @"CIDifferenceBlendMode"];
			[theFilter setDefaults];
			//[theLayer setSize: [self bounds].size];
			[theLayer setCompositingFilter: theFilter];
		}
#endif
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[bt setCell: [[[WILDButtonCell alloc] initTextCell: @""] autorelease]];
		[bt setBordered: NO];
		[[bt cell] setBackgroundColor: [NSColor whiteColor]];
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart style] isEqualToString: @"rectangle"]
			|| [[currPart style] isEqualToString: @"shadow"]
			|| [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
	{
		WILDButtonCell*	ourCell = [[[WILDButtonCell alloc] initTextCell: @""] autorelease];
		[bt setCell: ourCell];
		[[bt cell] setBackgroundColor: [NSColor whiteColor]];
		[bt setBordered: YES];
		
		if( [[currPart style] isEqualToString: @"shadow"]
			|| [[currPart style] isEqualToString: @"roundrect"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[bt layer] setShadowColor: theColor];
			[[bt layer] setShadowOpacity: 0.8];
			[[bt layer] setShadowOffset: CGSizeMake( 1, -1 )];
			[[bt layer] setShadowRadius: 0.0];
			CFRelease( theColor );
			
			// Compensate for shadow
			partRect.size.width -= 1;
			partRect.size.height -= 1;
			partRect.origin.y += 1;
			[bt setFrame: partRect];
		}
		
		if( [[currPart style] isEqualToString: @"roundrect"]
			|| [[currPart style] isEqualToString: @"standard"]
			|| [[currPart style] isEqualToString: @"default"] )
			[bt setBezelStyle: NSRoundedBezelStyle];
		
		if( [[currPart style] isEqualToString: @"default"] )
		{
			[bt setKeyEquivalent: @"\r"];
			[ourCell setDrawAsDefault: YES];
		}
		[bt setAlignment: [currPart textAlignment]];	
		[bt setButtonType: NSMomentaryPushInButton];
	}
	else if( [[currPart style] isEqualToString: @"checkbox"] )
	{
		[bt setButtonType: NSSwitchButton];
		canHaveIcon = NO;
	}
	else if( [[currPart style] isEqualToString: @"radiobutton"] )
	{
		[bt setButtonType: NSRadioButton];
		canHaveIcon = NO;
	}

	[bt setFont: [currPart textFont]];
	if( [currPart showName] )
		[bt setTitle: [currPart name]];
	[bt setTarget: self];
	[bt setAction: @selector(updateOnClick:)];
	[bt setState: isHighlighted ? NSOnState : NSOffState];
	
	if( canHaveIcon && [currPart iconID] != 0 )
	{
		[bt setImage: [currPart iconImage]];
		
		if( [currPart iconID] == -1 || [[currPart name] length] == 0
			|| ![currPart showName] )
			[bt setImagePosition: NSImageOnly];
		else
			[bt setImagePosition: NSImageAbove];
		if( [currPart iconID] != -1 && [currPart iconID] != 0 )
			[bt setFont: [NSFont fontWithName: @"Geneva" size: 9.0]];
		[[bt cell] setImageScaling: NSImageScaleNone];
	}
	
	[self addSubview: bt];
	[bt setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setMainView: bt];
	
	[bt release];
}


-(void)	loadButton: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	if( [[currPart style] isEqualToString: @"popup"] )
	{
		[self loadPopupButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else
	{
		[self loadPushButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
}


-(void)	loadEditField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	WILDTextView	*	tv = [[WILDTextView alloc] initWithFrame: partRect];
	[tv setFont: [currPart textFont]];
	[tv setWantsLayer: YES];
	[tv setUsesFindPanel: NO];
	[tv setDelegate: self];
	[tv setAlignment: [currPart textAlignment]];
	if( [currPart wideMargins] )
		[tv setTextContainerInset: NSMakeSize( 5, 2 )];
	[tv setRepresentedPart: currPart];
	
	NSAttributedString*	attrStr = [contents styledTextForPart: currPart];
	if( attrStr )
		[[tv textStorage] setAttributedString: attrStr];
	else
	{
		NSString*	theText = [contents text];
		if( theText )
			[tv setString: [contents text]];
	}
	
	// A field can be edited if:
	//	It is a card field and its lockText is FALSE.
	//	It is a bg field, its lockText is FALSE its sharedText is TRUE and we're editing the background.
	//	It is a bg field, its lockText is FALSE and its sharedText is FALSE.
	BOOL		shouldBeEditable = ![currPart lockText] && (![currPart sharedText] || backgroundEditMode);
	[tv setEditable: shouldBeEditable];
	[tv setSelectable: shouldBeEditable];
	
	NSScrollView*	sv = [[WILDScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[[currPart stack] document] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = partRect;
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setDrawsBackground: NO];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setHasVerticalScroller: NO];
		[sv setBackgroundColor: [NSColor whiteColor]];
	}
	else if( [[currPart style] isEqualToString: @"scrolling"] )
	{
		txBox.size.width -= 15;
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: YES];
	}
	else
	{
		if( [[currPart style] isEqualToString: @"shadow"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[sv layer] setShadowColor: theColor];
			[[sv layer] setShadowOpacity: 0.8];
			[[sv layer] setShadowOffset: CGSizeMake( 2, -2 )];
			[[sv layer] setShadowRadius: 0.0];
			CFRelease( theColor );
			
			txBox.size.width -= 2;
			txBox.size.height -= 2;
			txBox.origin.y += 2;
			
			partRect.size.width -= 2;
			partRect.size.height -= 2;
			partRect.origin.y += 2;
			[sv setFrame: partRect];
		}
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	[sv setHasHorizontalScroller: NO];
	[tv setFrame: txBox];
	[sv setDocumentView: tv];
	[sv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self addSubview: sv];
	[self setHelperView: sv];
	[self setMainView: tv];
	
	[tv release];
}


-(void)	loadListField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	// Build the table view:
	NSTableView	*	tv = [[NSTableView alloc] initWithFrame: partRect];
	[tv setWantsLayer: YES];
	[tv setFont: [currPart textFont]];
	[tv setAlignment: [currPart textAlignment]];
	[tv setColumnAutoresizingStyle: NSTableViewUniformColumnAutoresizingStyle];
	if( [currPart showLines] )
	{
		[tv setGridStyleMask: NSTableViewSolidHorizontalGridLineMask];
		[tv setGridColor: [NSColor lightGrayColor]];
	}
	else
		[tv setGridStyleMask: NSTableViewGridNone];
	[tv setAllowsColumnSelection: NO];
	[tv setAllowsMultipleSelection: [currPart canSelectMultipleLines]];
	[tv setHeaderView: nil];
	
	NSTableColumn*		tc = [[NSTableColumn alloc] initWithIdentifier: @"mainColumn"];
	NSTextFieldCell*	dc = [[NSTextFieldCell alloc] initTextCell: @"Are you my mommy?"];
	[tc setDataCell: dc];
	[dc release];
	[tv addTableColumn: tc];
	[tc release];
	NSArrayController*	arrayc = [[NSArrayController alloc] init];
	[arrayc setContent: [contents listItems]];
	[tv bind: @"content" toObject: arrayc withKeyPath: @"arrangedObjects" options: nil];
	[tc bind: @"value" toObject: arrayc withKeyPath: @"arrangedObjects.description" options: nil];
	[arrayc release];
	
	// Build surrounding scroll view:
	NSScrollView*	sv = [[WILDScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [[[currPart stack] document] cursorWithID: 128]];
	[sv setWantsLayer: YES];
	NSRect			txBox = [currPart rectangle];
	txBox.origin = NSZeroPoint;
	if( [[currPart style] isEqualToString: @"transparent"] )
	{
		[sv setBorderType: NSNoBorder];
		[sv setDrawsBackground: NO];
		[tv setBackgroundColor: [NSColor clearColor]];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"opaque"] )
	{
		[sv setBorderType: NSNoBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	else if( [[currPart style] isEqualToString: @"scrolling"] )
	{
		txBox.size.width -= 15;
		[sv setBorderType: NSLineBorder];
		[tv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: YES];
	}
	else
	{
		if( [[currPart style] isEqualToString: @"shadow"] )
		{
			CGColorRef theColor = CGColorCreateGenericRGB( 0.4, 0.4, 0.4, 1.0 );
			[[sv layer] setShadowColor: theColor];
			[[sv layer] setShadowOpacity: 0.8];
			[[sv layer] setShadowOffset: CGSizeMake( 2, -2 )];
			[[sv layer] setShadowRadius: 0.0];
			CFRelease( theColor );
		}
		[sv setBorderType: NSLineBorder];
		[sv setBackgroundColor: [NSColor whiteColor]];
		[sv setHasVerticalScroller: NO];
	}
	[sv setHasHorizontalScroller: NO];
	[tv setFrame: txBox];
	[tc setWidth: txBox.size.width];
	[tc setMaxWidth: 1000000.0];
	[tc setMinWidth: 10.0];
	[sv setDocumentView: tv];
	[sv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self addSubview: sv];
	[self setHelperView: sv];
	[self setMainView: tv];

	NSIndexSet*	idxes = [currPart selectedListItemIndexes];
	if( idxes )
		[tv selectRowIndexes: idxes byExtendingSelection: NO];
	
	[tv release];
}


-(void)	loadField: (WILDPart*)currPart withCardContents: (WILDPartContents*)contents
			 withBgContents: (WILDPartContents*)bgContents forBackgroundEditing: (BOOL)backgroundEditMode
{
	if( [currPart autoSelect] && [currPart lockText] )
	{
		[self loadListField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else if( [[currPart style] isEqualToString: @"transparent"] || [[currPart style] isEqualToString: @"opaque"]
		 || [[currPart style] isEqualToString: @"rectangle"] || [[currPart style] isEqualToString: @"shadow"]
		|| [[currPart style] isEqualToString: @"scrolling"] )
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
	else
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	}
}


-(void)	loadPart: (WILDPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode
{
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	
	mIsBackgroundEditing = backgroundEditMode;
	mPart = currPart;
	
	contents = [self currentPartContentsAndBackgroundContents: &bgContents create: NO];
	
	if( [[currPart partType] isEqualToString: @"button"] )
		[self loadButton: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
	else
		[self loadField: currPart withCardContents: contents withBgContents: bgContents forBackgroundEditing: backgroundEditMode];
}


-(WILDPartContents*)	currentPartContentsAndBackgroundContents: (WILDPartContents**)outBgContents create: (BOOL)inDoCreate
{
	WILDCardView*		winView = [self enclosingCardView];
	WILDCard*			theCd = [winView card];
	
	return [mPart currentPartContentsAndBackgroundContents: outBgContents create: inDoCreate onCard: theCd forBackgroundEditing: mIsBackgroundEditing];
}


-(NSRect)	frameInScreenCoordinates
{
	NSRect				buttonRect = [mPart rectangle];
	WILDCardView	*	cardView = [self enclosingCardView];
	buttonRect = [cardView convertRectToBase: buttonRect];
	buttonRect.origin = [[cardView window] convertBaseToScreen: buttonRect.origin];
	return buttonRect;
}


//-(void)	drawRect:(NSRect)dirtyRect
//{
//	[[NSColor blueColor] set];
//	[NSBezierPath strokeRect: [self bounds]];
//}

@end
