//
//  UKPropagandaSelectionView.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaSelectionView.h"
#import "UKPropagandaNotifications.h"
#import "UKPropagandaScriptEditorWindowController.h"
#import "UKPropagandaPart.h"
#import "UKPropagandaPartContents.h"
#import "UKPropagandaButtonInfoWindowController.h"
#import "UKPropagandaFieldInfoWindowController.h"
#import "UKPropagandaWindowBodyView.h"
#import "UKPropagandaClickablePopUpButtonLabel.h"
#import "WILDButtonCell.h"
#import "UKPropagandaTextView.h"
#import "UKIsDragStart.h"


@class UKPropagandaWindowBodyView;


@implementation UKPropagandaSelectionView

@synthesize control = mControl;
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
	[[UKPropagandaTools propagandaTools] removeClient: self];
	[self unsubscribeNotifications];
	
	[super dealloc];
}


-(void)	unsubscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: UKPropagandaCurrentToolDidChangeNotification
											object: nil];
}


-(void)	subscribeNotifications
{
	if( !mPart )
		return;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
											name: UKPropagandaPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partWillChange:)
											name: UKPropagandaPartWillChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(partDidChange:)
											name: UKPropagandaPartDidChangeNotification
											object: mPart];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
											name: UKPropagandaCurrentToolDidChangeNotification
											object: nil];
}


-(void)	highlightSearchResultInRange: (NSRange)theRange
{
	[(NSTextView*)mHelperView setSelectedRange: theRange];
	[(NSTextView*)mHelperView scrollRangeToVisible: theRange];
	[(NSTextView*)mHelperView showFindIndicatorForRange: theRange];
}


-(void)	setSelected: (BOOL)inState
{
	if( mSelected != inState )
	{
		mSelected = inState;
		
		if( mSelected )
			[[UKPropagandaTools propagandaTools] addClient: self];
		else
			[[UKPropagandaTools propagandaTools] removeClient: self];
	}
}


-(void)	drawRect: (NSRect)dirtyRect
{
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
   
    if( mPeeking )
	{
		NSRect	peekBox = NSInsetRect( [self bounds], 3, 3 );
		[NSBezierPath setDefaultLineWidth: 2];
		[[NSColor lightGrayColor] set];
		[NSBezierPath strokeRect: peekBox];
		[[[UKPropagandaTools propagandaTools] peekPattern] set];
		[NSBezierPath strokeRect: peekBox];
		[NSBezierPath setDefaultLineWidth: 1];
	}
	
	if( mSelected )
	{
		[[NSColor keyboardFocusIndicatorColor] set];
		NSRect	clampedBounds = [self bounds];
		clampedBounds.origin.x = truncf(clampedBounds.origin.x) + 2.5;
		clampedBounds.origin.y = truncf(clampedBounds.origin.y) + 2.5;
		clampedBounds.size.width -= 5;
		clampedBounds.size.height -= 5;
		NSBezierPath*	selPath = [NSBezierPath bezierPathWithRect: NSInsetRect(clampedBounds, 1, 1)];
		CGFloat			pattern[2] = { 4, 4 };
		[[NSColor whiteColor] set];
		[selPath stroke];
		[selPath setLineDash: pattern count: 2 phase: [[UKPropagandaTools propagandaTools] animationPhase]];
		[[NSColor keyboardFocusIndicatorColor] set];
		[selPath stroke];
	}
	else if( isMyTool )
	{
		[[NSColor grayColor] set];
		NSRect	peekBox = NSInsetRect( [self bounds], 3.5, 3.5 );
		[NSBezierPath strokeRect: peekBox];
		[[NSColor blackColor] set];
	}
}


-(NSView *)	hitTest: (NSPoint)aPoint	// Equivalent to Carbon kEventControlInterceptSubviewClick.
{
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
	NSView*	hitView = [super hitTest: aPoint];
	if( hitView != nil )	// Was in our view or a sub view, not outside us?
	{
		if( mPeeking || isMyTool )
			hitView = self;		// Redirect to us.
		else if( [[UKPropagandaTools propagandaTools] currentTool] != UKPropagandaBrowseTool )	// Another tool than the ones we support?
			hitView = nil;	// Pretend we (or our subviews) weren't hit at all.
		else if( [[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaBrowseTool && hitView == self )	// Browse tool but not in our subviews?
			hitView = nil;	// Pretend we weren't hit at all. Maybe a view under us does better.
	}
	
	return hitView;
}


-(void)	mouseDown: (NSEvent*)event
{
	BOOL	isMyTool = ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaButtonTool && [[mPart partType] isEqualToString: @"button"])
						|| ([[UKPropagandaTools propagandaTools] currentTool] == UKPropagandaFieldTool && [[mPart partType] isEqualToString: @"field"]);
	if( mPeeking )
	{
		UKPropagandaScriptEditorWindowController*	sewc = [[[UKPropagandaScriptEditorWindowController alloc] initWithScriptContainer: mPart] autorelease];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( isMyTool )
	{
		if( [event clickCount] == 2 && mSelected )
		{
			NSWindow*	infoController = nil;
			if( [[mPart partType] isEqualToString: @"button"] )
				infoController = [[UKPropagandaButtonInfoWindowController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];
			else
				infoController = [[UKPropagandaFieldInfoWindowController alloc] initWithPart: mPart ofCardView: [self enclosingCardView]];

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
				NSPasteboard*   		pb = [NSPasteboard pasteboardWithName: NSDragPboard];
				[pb clearContents];
				NSPoint					dragStartImagePos = NSZeroPoint;
				NSArray*				selectedObjects = [[[UKPropagandaTools propagandaTools] clients] allObjects];
				NSImage*				theDragImg = [self imageForPeerViews: selectedObjects
														dragStartImagePos: &dragStartImagePos];
				UKPropagandaCard*		currCard = [[self enclosingCardView] card];
				UKPropagandaBackground*	currBg = [currCard owningBackground];
				
				NSMutableString*		xmlString = [[[NSMutableString alloc] init] autorelease];
				for( UKPropagandaSelectionView* selView in selectedObjects )
				{
					UKPropagandaPart*	thePart = [selView representedPart];
					[xmlString appendString: [thePart xmlString]];
					NSString*	cdXmlStr = [[currCard contentsForPart: thePart] xmlString];
					if( cdXmlStr )
						[xmlString appendString: cdXmlStr];
					NSString*	bgXmlStr = [[currBg contentsForPart: thePart] xmlString];
					if( bgXmlStr )
						[xmlString appendString: bgXmlStr];
				}
				
				[pb addTypes: [NSArray arrayWithObject: NSStringPboardType] owner: self];
				[pb setString: xmlString forType: NSStringPboardType];
				
				// Actually commence the drag:
				[self dragImage: theDragImg at: dragStartImagePos offset: NSMakeSize(0,0)
							event: event pasteboard: pb source: self slideBack: YES];
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
		[[UKPropagandaTools propagandaTools] deselectAllClients];
		[self setSelected: YES];
	}
	[self setNeedsDisplay: YES];
}


-(NSImage*)	imageForPeerViews: (NSArray*)views dragStartImagePos: (NSPoint*)dragStartImagePos
{
	CGFloat		minX = LONG_MAX, maxX = LONG_MIN, minY = LONG_MAX, maxY = LONG_MIN;
	
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
	
	for( UKPropagandaSelectionView* theView in views )
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
		[theLayer renderInContext: currContext];
		theView->mSelected = wasSelected;
		
		[NSGraphicsContext restoreGraphicsState];
	}
	[theImage unlockFocus];
	
	dragStartImagePos->x = -[self frame].origin.x +minX;
	dragStartImagePos->y = -[self frame].origin.y +minY;
	
	return theImage;
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	mPeeking = [[[notification userInfo] objectForKey: UKPropagandaPeekingStateKey] boolValue];
	[self setNeedsDisplay: YES];
}


-(void)	setRepresentedPart: (UKPropagandaPart*)inPart
{
	if( inPart == nil )
		[self unsubscribeNotifications];
	
	mPart = inPart;
	
	if( mPart != nil )
		[self subscribeNotifications];
}


-(UKPropagandaPart*)	representedPart
{
	return mPart;
}


-(UKPropagandaWindowBodyView*)	enclosingCardView
{
	UKPropagandaWindowBodyView*		mySuper = (UKPropagandaWindowBodyView*) [self superview];
	if( mySuper && [mySuper isKindOfClass: [UKPropagandaWindowBodyView class]] )
		return mySuper;
	else
		return nil;
}

-(void)	partWillChange: (NSNotification*)notification
{
	
}


-(void)	partDidChange: (NSNotification*)notification
{
	NSString*	thePropName = [[notification userInfo] objectForKey: UKPropagandaAffectedPropertyKey];
	if( [thePropName isEqualToString: @"highlighted"] && [mControl respondsToSelector: @selector(setState:)] )
	{
		//NSLog( @"View got notified that %@ highlight changed to %s", [mPart displayName], [mPart highlighted] ? "true" : "false" );
		[(NSButton*)mControl setState: [mPart highlighted] ? NSOnState : NSOffState];
	}
	else if( [thePropName isEqualToString: @"visible"] && [mControl respondsToSelector: @selector(setHidden:)] )
	{
		//NSLog( @"View got notified that %@ highlight changed to %s", [mPart displayName], [mPart highlighted] ? "true" : "false" );
		[self setHidden: ![mPart visible]];
	}
	else if( [thePropName isEqualToString: @"enabled"] && [mControl respondsToSelector: @selector(setEnabled:)] )
	{
		//NSLog( @"View got notified that %@ highlight changed to %s", [mPart displayName], [mPart highlighted] ? "true" : "false" );
		[(NSButton*)mControl setEnabled: [mPart isEnabled]];
	}
	else if( [thePropName isEqualToString: @"icon"] && [mControl respondsToSelector: @selector(setImage:)] )
	{
		//NSLog( @"View got notified that %@ highlight changed to %s", [mPart displayName], [mPart highlighted] ? "true" : "false" );
		[(NSButton*)mControl setImage: [mPart iconImage]];
	}
	else
	{
		[self unloadPart];
		[self loadPart: mPart forBackgroundEditing: NO];
	}
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[self setSelected: NO];
	[self setNeedsDisplay: YES];
}


-(void)	unloadPart
{
	NSArray*	subviews = [[[self subviews] copy] autorelease];
	for( NSView* currView in subviews )
		[currView removeFromSuperview];
	[self setControl: nil];
	[self setHelperView: nil];
	[self unsubscribeNotifications];
}


-(void)	loadPopupButton: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	NSRect			partRect = [currPart rectangle];
	NSTextField*	label = nil;
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setRepresentedPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	NSRect		popupBox = partRect;
	if( [currPart titleWidth] > 0 )
	{
		NSRect	titleBox = popupBox;
		titleBox.size.width = [currPart titleWidth];
		popupBox.origin.x += titleBox.size.width;
		popupBox.size.width -= titleBox.size.width;
		
		label = [[UKPropagandaClickablePopUpButtonLabel alloc] initWithFrame: titleBox];
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
		
		[self setHelperView: label];
	}
	
	NSPopUpButton	*	bt = [[NSPopUpButton alloc] initWithFrame: popupBox];
	[bt setWantsLayer: YES];
	[bt setFont: [currPart textFont]];
	
	NSArray*	popupItems = ([contents text] != nil) ? [contents listItems] : [bgContents listItems];
	for( NSString* itemName in popupItems )
	{
		if( [itemName hasPrefix: @"-"] )
			[[bt menu] addItem: [NSMenuItem separatorItem]];
		else
			[bt addItemWithTitle: itemName];
	}
	[bt selectItemAtIndex: [[currPart selectedListItemIndexes] firstIndex]];
	[bt setState: [currPart highlighted] ? NSOnState : NSOffState];
	
	if( [self helperView] )
		[(UKPropagandaClickablePopUpButtonLabel*)[self helperView] setPopUpButton: bt];
	
	[self addSubview: bt];
	
	[self setControl: bt];
	
	if( label )
		[[bt cell] accessibilitySetOverrideValue: [label cell] forAttribute: NSAccessibilityTitleUIElementAttribute];
	
	[bt release];
}


-(void)	loadPushButton: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setRepresentedPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	BOOL			canHaveIcon = YES;
	NSButton	*	bt = [[NSButton alloc] initWithFrame: partRect];
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
	[bt setTitle: [currPart name]];
	[bt setTarget: currPart];
	[bt setAction: @selector(updateOnClick:)];
	BOOL		isHighlighted = [currPart highlighted];
	if( ![currPart sharedHighlight] && [[currPart partLayer] isEqualToString: @"background"] )
		isHighlighted = [contents highlighted];
	[bt setState: isHighlighted ? NSOnState : NSOffState];
	
	if( canHaveIcon )
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
	[self setControl: bt];
	
	[bt release];
}


-(void)	loadButton: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	if( [[currPart style] isEqualToString: @"popup"] )
	{
		[self loadPopupButton: currPart withCardContents: contents withBgContents: bgContents];
	}
	else
	{
		[self loadPushButton: currPart withCardContents: contents withBgContents: bgContents];
	}
}


-(void)	loadEditField: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setRepresentedPart: currPart];
	partRect.origin = NSMakePoint( 2, 2 );
	
	UKPropagandaTextView	*	tv = [[UKPropagandaTextView alloc] initWithFrame: partRect];
	[tv setFont: [currPart textFont]];
	[tv setWantsLayer: YES];
	[tv setUsesFindPanel: NO];
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
	
	[tv setEditable: ![currPart textLocked]];
	[tv setSelectable: ![currPart textLocked]];
	
	NSScrollView*	sv = [[NSScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [NSCursor arrowCursor]];
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
	[self addSubview: sv];
	[self setHelperView: tv];
	
	[tv release];
}


-(void)	loadListField: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	NSRect						partRect = [currPart rectangle];
	[self setHidden: ![currPart visible]];
	[self setWantsLayer: YES];
	[self setRepresentedPart: currPart];
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
	NSScrollView*	sv = [[NSScrollView alloc] initWithFrame: partRect];
	[sv setDocumentCursor: [NSCursor arrowCursor]];
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
	[self addSubview: sv];
	[self setHelperView: tv];

	NSIndexSet*	idxes = [currPart selectedListItemIndexes];
	if( idxes )
		[tv selectRowIndexes: idxes byExtendingSelection: NO];
	
	[tv release];
}


-(void)	loadField: (UKPropagandaPart*)currPart withCardContents: (UKPropagandaPartContents*)contents
			 withBgContents: (UKPropagandaPartContents*)bgContents
{
	if( [currPart autoSelect] && [currPart textLocked] )
	{
		[self loadListField: currPart withCardContents: contents withBgContents: bgContents];
	}
	else if( [[currPart style] isEqualToString: @"transparent"] || [[currPart style] isEqualToString: @"opaque"]
		 || [[currPart style] isEqualToString: @"rectangle"] || [[currPart style] isEqualToString: @"shadow"]
		|| [[currPart style] isEqualToString: @"scrolling"] )
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents];
	}
	else
	{
		[self loadEditField: currPart withCardContents: contents withBgContents: bgContents];
	}
}


-(void)	loadPart: (UKPropagandaPart*)currPart forBackgroundEditing: (BOOL)backgroundEditMode
{
	UKPropagandaWindowBodyView*	winView = [self enclosingCardView];
	UKPropagandaCard*			theCd = [winView card];
	UKPropagandaBackground*		theBg = [theCd owningBackground];
	UKPropagandaPartContents*	contents = nil;
	UKPropagandaPartContents*	bgContents = nil;
	bgContents = [theBg contentsForPart: currPart];
	if( [currPart sharedText] )
		contents = bgContents;
	else
		contents = backgroundEditMode ? nil : [theCd contentsForPart: currPart];

	if( [[currPart partType] isEqualToString: @"button"] )
		[self loadButton: currPart withCardContents: contents withBgContents: bgContents];
	else
		[self loadField: currPart withCardContents: contents withBgContents: bgContents];
}

@end
