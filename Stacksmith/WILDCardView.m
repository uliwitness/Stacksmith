//
//  WILDCardView.m
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardView.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDNotifications.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDPartView.h"
#import "WILDPresentationConstants.h"
#import "WILDXMLUtils.h"
#import "WILDPart.h"
#import "WILDCardViewController.h"
#import "NSImage+NiceScaling.h"
#import "WILDGuidelineView.h"
#import <QuartzCore/QuartzCore.h>
#import "UKHelperMacros.h"


@implementation WILDCardView

@synthesize transitionType = mTransitionType;
@synthesize transitionSubtype = mTransitionSubtype;

-(id)	initWithFrame: (NSRect)frameRect
{
	if(( self = [super initWithFrame: frameRect] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
		[self registerForDraggedTypes: [NSArray arrayWithObject: WILDPartPboardType]];
	}
	
	return self;
}


-(id)	initWithCoder: (NSCoder *)aDecoder
{
	if(( self = [super initWithCoder: aDecoder] ))
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(peekingStateChanged:)
												name: WILDPeekingStateChangedNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(currentToolDidChange:)
												name: WILDCurrentToolDidChangeNotification
												object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(backgroundEditModeChanged:)
												name: WILDBackgroundEditModeChangedNotification
												object: nil];
		[self registerForDraggedTypes: [NSArray arrayWithObject: WILDPartPboardType]];
	}
	
	return self;
}


-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDPeekingStateChangedNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDCurrentToolDidChangeNotification
											object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
											name: WILDBackgroundEditModeChangedNotification
											object: nil];
	
	DESTROY_DEALLOC(mTransitionType);
	DESTROY_DEALLOC(mTransitionSubtype);
//	if( mCursorTrackingArea )
//		[self removeTrackingArea: mCursorTrackingArea];
//	DESTROY_DEALLOC(mCursorTrackingArea);
	
	[super dealloc];
}


-(void)	setCard: (WILDCard*)inCard
{
	mCard = inCard;
}


-(WILDCard*)	card
{
	return mCard;
}


#if USE_CURSOR_RECTS

-(void)	resetCursorRects
{
	WILDTool			currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( mPeeking )
		currCursor = [NSCursor arrowCursor];
	if( !currCursor )
		currCursor = [[[mCard stack] document] cursorWithID: 128];
	[self addCursorRect: [self visibleRect] cursor: currCursor];
}

#else // !USE_CURSOR_RECTS

-(void)	mouseEntered:(NSEvent *)theEvent
{
	WILDTool			currTool = [[WILDTools sharedTools] currentTool];
	NSCursor*			currCursor = [WILDTools cursorForTool: currTool];
	if( mPeeking )
		currCursor = [NSCursor arrowCursor];
	if( !currCursor )
		currCursor = [[[mCard stack] document] cursorWithID: 128];
	[currCursor set];
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	
}


- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mCursorTrackingArea )
	{
		[self removeTrackingArea: mCursorTrackingArea];
		DESTROY(mCursorTrackingArea);
	}
	
	mCursorTrackingArea = [[NSTrackingArea alloc] initWithRect: [self visibleRect] options: NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner: self userInfo: nil];
	[self addTrackingArea: mCursorTrackingArea];
}

#endif // USE_CURSOR_RECTS

-(void)	mouseDown: (NSEvent*)event
{
	if( mPeeking )
	{
		WILDScriptEditorWindowController*	sewc = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mBackgroundEditMode ? [mCard owningBackground] : mCard] autorelease];
		NSRect	wFrame = [[self window] contentRectForFrameRect: [[self window] frame]];
		NSRect	theBox = { {0,0}, {32,32} };
		theBox.origin = [event locationInWindow];
		
		theBox.origin.x += wFrame.origin.x -16;
		theBox.origin.y += wFrame.origin.y -16;
		[sewc setGlobalStartRect: theBox];
		[[[[self window] windowController] document] addWindowController: sewc];
		[sewc showWindow: nil];
	}
	else if( [[WILDTools sharedTools] currentTool] == WILDButtonTool
				|| [[WILDTools sharedTools] currentTool] == WILDFieldTool
				|| [[WILDTools sharedTools] currentTool] == WILDMoviePlayerTool
				|| [[WILDTools sharedTools] currentTool] == WILDPointerTool )
	{
		[[WILDTools sharedTools] deselectAllClients];
		[[self guidelineView] removeAllSelectedPartViews];
	}
	else
	{
		[[self window] makeFirstResponder: self];
		[super mouseDown: event];
	}
}


-(void)	peekingStateChanged: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
	mPeeking = [[[notification userInfo] objectForKey: WILDPeekingStateKey] boolValue];
	[[self guidelineView] setNeedsDisplay: YES];
}


-(void)	backgroundEditModeChanged: (NSNotification*)notification
{
	mBackgroundEditMode = [[[notification userInfo] objectForKey: WILDBackgroundEditModeKey] boolValue];
}


-(void)	currentToolDidChange: (NSNotification*)notification
{
	[[self window] invalidateCursorRectsForView: self];
	[[self window] makeFirstResponder: self];
	[[self guidelineView] setNeedsDisplay: YES];
}


-(BOOL)	acceptsFirstResponder
{
	return YES;
}


-(NSDragOperation)	draggingEntered: (id <NSDraggingInfo>)sender
{
	return( ([sender draggingSource] == self) ? NSDragOperationMove : NSDragOperationCopy );
}


-(BOOL)	performDragOperation: (id <NSDraggingInfo>)sender
{
	NSDragOperation	op = [sender draggingSourceOperationMask];
	NSPoint			pos = [self convertPoint: [sender draggedImageLocation] fromView: nil];
	NSPasteboard*	pb = [sender draggingPasteboard];
	NSString*		xmlStr = [pb stringForType: WILDPartPboardType];
	NSError*		err = nil;
	NSXMLDocument*	doc = [[[NSXMLDocument alloc] initWithXMLString: xmlStr options: 0 error: &err] autorelease];
	NSArray*		parts = [[doc rootElement] elementsForName: @"part"];
	
	if( [sender draggingSource] == self )	// Internal drag.
	{
		NSMutableArray*		draggedParts = [NSMutableArray arrayWithCapacity: [parts count]];
		
		for( NSXMLElement* currPartXml in parts )
		{
			NSInteger	theID = WILDIntegerFromSubElementInElement( @"id", currPartXml );
			NSString*	theLayer = WILDStringFromSubElementInElement( @"layer", currPartXml );
			WILDPart*	thePart = nil;
			if( [theLayer isEqualToString: @"card"] )
				thePart = [mCard partWithID: theID];
			else if( [theLayer isEqualToString: @"background"] )
				thePart = [[mCard owningBackground] partWithID: theID];
			[draggedParts addObject: thePart];
		}
		
		NSPoint		dragStartImagePos = NSZeroPoint;
		NSRect		box = [WILDPartView rectForPeers: draggedParts dragStartImagePos: &dragStartImagePos];
		
		NSPoint		diff = pos;
		diff.x -= box.origin.x;
		diff.y = [self bounds].size.height -diff.y;
		diff.y -= box.origin.y +box.size.height;
		diff.x = truncf(diff.x);
		diff.y = truncf(diff.y);
		//NSLog( @"diff = %@ (src = %@ dst = %@)", NSStringFromPoint(diff), NSStringFromPoint(box.origin), NSStringFromPoint(pos) );
		
		for( WILDPart* currPart in draggedParts )
		{
			NSRect		currPartBox;
			currPartBox = [currPart flippedRectangle];
			currPartBox = NSOffsetRect( currPartBox, diff.x, diff.y );
			[currPart setFlippedRectangle: currPartBox];
		}
		
		[mOwner reloadCard];
	}
	else
		;//NSLog( @"external" );
	
	return YES;
}


-(void)		setOwner: (WILDCardViewController*)inOwner
{
	mOwner = inOwner;
}


-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind
{
	return [mOwner visibleObjectForWILDObject: inObjectToFind];
}

-(NSImage*)	snapshotImage
{
	NSImage*	img = [[[NSImage alloc] initWithSize: [self bounds].size] autorelease];
	
	[img lockFocus];
		[[self layer] renderInContext: [[NSGraphicsContext currentContext] graphicsPort]];
	[img unlockFocus];
	
	return img;
}


-(NSImage*)	thumbnailImage
{
	NSImage*	img = [self snapshotImage];
	return [img scaledImageToFitSize: NSMakeSize(128,96)];	// 4:3 aspect ratio.
}


-(id)	animationForKey:(NSString *)key
{
	NSAnimation	*	ani = nil;
	
	if( [key isEqualToString: @"subviews"] && mTransitionType && mTransitionSubtype )
	{
		ani = [CATransition animation];
		if( [mTransitionType hasPrefix: @"CI"] || [mTransitionType hasPrefix: @"WILD"] )
		{
			CIFilter	*	theFilter = [CIFilter filterWithName: mTransitionType];
			[theFilter setDefaults];
			static NSDictionary*	sTransitionSubtypes = nil;
			if( !sTransitionSubtypes )
			{
				sTransitionSubtypes = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSNumber numberWithDouble: -M_PI_4], @"fromLeft",
										[NSNumber numberWithDouble: -M_PI_2 -M_PI_4], @"fromTop",
										[NSNumber numberWithDouble: M_PI], @"fromRight",
										[NSNumber numberWithDouble: M_PI_2 +M_PI_4], @"fromBottom",
										[NSNumber numberWithInt: 1000], @"cifilter",
										nil];
			}
			NSNumber*	theNumber = [sTransitionSubtypes objectForKey: mTransitionSubtype];
			if( [theNumber intValue] >= 1000 )
			{
				//[theFilter setValue: [NSNumber numberWithDouble: 1.0] forKey: @"percentage"];
			}
			else
				[theFilter setValue: theNumber forKey: kCIInputAngleKey];
			[ani setFilter: theFilter];
		}
		else
		{
			[ani setType: mTransitionType];
			[ani setSubtype: mTransitionSubtype];
		}
	}
	
	return ani;
}


-(WILDGuidelineView*)	guidelineView
{
	return [mOwner guidelineView];
}


static void FillFirstFreeOne( NSString ** a, NSString ** b, NSString ** d, NSString ** c, NSString* theAppendee )
{
	if( *a == nil )
		*a = theAppendee;
	else if( *b == nil )
		*b = theAppendee;
	else if( *c == nil )
		*c = theAppendee;
	else if( *d == nil )
		*d = theAppendee;
}


-(void)	keyDown: (NSEvent *)theEvent
{
	BOOL	passOn = YES;
	
	if( [WILDTools sharedTools].currentTool == WILDBrowseTool )
	{
		NSString	*	firstModifier = nil;
		NSString	*	secondModifier = nil;
		NSString	*	thirdModifier = nil;
		NSString	*	fourthModifier = nil;
		
		if( theEvent.modifierFlags & NSShiftKeyMask )
			FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, @"shift" );
		else if( theEvent.modifierFlags & NSAlphaShiftKeyMask )
			FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, @"shiftlock" );
		if( theEvent.modifierFlags & NSAlternateKeyMask )
			FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, @"alternate" );
		if( theEvent.modifierFlags & NSControlKeyMask )
			FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, @"control" );
		if( theEvent.modifierFlags & NSCommandKeyMask )
			FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, @"command" );
		
		if( !firstModifier ) firstModifier = @"";
		if( !secondModifier ) secondModifier = @"";
		if( !thirdModifier ) thirdModifier = @"";
		if( !fourthModifier ) fourthModifier = @"";
		
		WILDScriptContainerResultFromSendingMessage( mCard, @"keyDown %@,%@,%@,%@,%@", [theEvent characters], firstModifier, secondModifier, thirdModifier, fourthModifier );

		if( theEvent.charactersIgnoringModifiers.length > 0 )
		{
			unichar theKey = [theEvent.charactersIgnoringModifiers characterAtIndex: 0];
			switch( theKey )
			{
				case NSLeftArrowFunctionKey:
					WILDScriptContainerResultFromSendingMessage( mCard, @"arrowKey %@,%@,%@,%@,%@", @"left", firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				case NSRightArrowFunctionKey:
					WILDScriptContainerResultFromSendingMessage( mCard, @"arrowKey %@,%@,%@,%@,%@", @"right", firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				case NSUpArrowFunctionKey:
					WILDScriptContainerResultFromSendingMessage( mCard, @"arrowKey %@,%@,%@,%@,%@", @"up", firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				case NSDownArrowFunctionKey:
					WILDScriptContainerResultFromSendingMessage( mCard, @"arrowKey %@,%@,%@,%@,%@", @"down", firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				case NSF1FunctionKey ... NSF35FunctionKey:
					WILDScriptContainerResultFromSendingMessage( mCard, @"functionKey %d,%@,%@,%@,%@", theKey -NSF1FunctionKey +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
			}
		}
	}
	
	if( passOn )
		[mOwner keyDown: theEvent];
}

@end
