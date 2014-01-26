//
//  WILDStackWindowController.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "WILDStackWindowController.h"
#include "CStackMac.h"
#include "CCard.h"
#include "CBackground.h"
#include "CDocument.h"
#include "CMacPartBase.h"
#include "CAlert.h"


static void FillFirstFreeOne( const char ** a, const char ** b, const char ** c, const char ** d, const char* theAppendee )
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


using namespace Carlson;


@implementation WILDFlippedContentView

-(BOOL)	isFlipped
{
	return YES;
}


-(NSView *)	hitTest: (NSPoint)aPoint
{
	NSView	*	hitView = [super hitTest: aPoint];
	bool	isPeeking = [(WILDStackWindowController*)[[self window] windowController] cppStack]->GetPeeking();
	if( isPeeking && hitView != nil )
		return self;
	return hitView;
}


-(void)	mouseDown: (NSEvent*)theEvt
{
	bool	isPeeking = [(WILDStackWindowController*)[[self window] windowController] cppStack]->GetPeeking();
	if( isPeeking )
	{
		NSPoint		hitPos = [self convertPoint: [theEvt locationInWindow] fromView: nil];
		CStack	*	theStack = [(WILDStackWindowController*)[[self window] windowController] cppStack];
		CCard	*	theCard = theStack->GetCurrentCard();
		bool		foundOne = false;
		
		size_t		numParts = theCard->GetNumParts();
		for( size_t x = numParts; x > 0; x-- )
		{
			CPart	*	thePart = theCard->GetPart( x-1 );
			if( !foundOne && hitPos.x > thePart->GetLeft() && hitPos.x < thePart->GetRight()
				&& hitPos.y > thePart->GetTop() && hitPos.y < thePart->GetBottom() )
			{
				thePart->SetSelected(true);
				foundOne = true;
			}
			else
				thePart->SetSelected(false);
		}
		numParts = theCard->GetBackground()->GetNumParts();
		for( size_t x = numParts; x > 0; x-- )
		{
			CPart	*	thePart = theCard->GetBackground()->GetPart( x-1 );
			if( !foundOne && hitPos.x > thePart->GetLeft() && hitPos.x < thePart->GetRight()
				&& hitPos.y > thePart->GetTop() && hitPos.y < thePart->GetBottom() )
			{
				thePart->SetSelected(true);
				foundOne = true;
			}
			else
				thePart->SetSelected(false);
		}
		[(WILDStackWindowController*)[[self window] windowController] drawBoundingBoxes];
	}
	else
		[self.window makeFirstResponder: self];
}


- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (BOOL)becomeFirstResponder
{
	return YES;
}


- (BOOL)resignFirstResponder
{
	return YES;
}


-(void)        keyDown: (NSEvent *)theEvent
{
	CStack *			theStack = [(WILDStackWindowController*)[[self window] windowController] cppStack];
	CCard *				theCard = theStack->GetCurrentCard();
	const char *        firstModifier = nil;
	const char *        secondModifier = nil;
	const char *        thirdModifier = nil;
	const char *        fourthModifier = nil;
	
	if( theEvent.modifierFlags & NSShiftKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shift" );
	else if( theEvent.modifierFlags & NSAlphaShiftKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shiftlock" );
	if( theEvent.modifierFlags & NSAlternateKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "alternate" );
	if( theEvent.modifierFlags & NSControlKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "control" );
	if( theEvent.modifierFlags & NSCommandKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "command" );
	
	if( !firstModifier ) firstModifier = "";
	if( !secondModifier ) secondModifier = "";
	if( !thirdModifier ) thirdModifier = "";
	if( !fourthModifier ) fourthModifier = "";
	
	std::function<void(const char *, size_t, size_t, CScriptableObject *)>	errHandler = [](const char * errMsg, size_t, size_t, CScriptableObject *)
	{
		if( errMsg )
			CAlert::RunMessageAlert( errMsg );
	};
	
	theCard->SendMessage( NULL, errHandler, "keyDown %s,%s,%s,%s,%s", [[theEvent characters] UTF8String], firstModifier, secondModifier, thirdModifier, fourthModifier );

	if( theEvent.charactersIgnoringModifiers.length > 0 )
	{
		unichar theKey = [theEvent.charactersIgnoringModifiers characterAtIndex: 0];
		switch( theKey )
		{
			case '\t':
				theCard->SendMessage( NULL, errHandler, "tabKey %s,%s,%s,%s", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case 0x0019:	// Back tab
				theCard->SendMessage( NULL, errHandler, "tabKey %s,%s,%s,%s", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
				
			case NSLeftArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "left", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSRightArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "right", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSUpArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "up", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSDownArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "down", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSF1FunctionKey ... NSF35FunctionKey:
				theCard->SendMessage( NULL, errHandler, "functionKey %d,%s,%s,%s,%s", (int)(theKey -NSF1FunctionKey +1), firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
		}
	}
}


//-(void)	resetCursorRects
//{
//	NSCursor	*	currentCursor = nil;
//	if( !currentCursor )
//	{
//		CStack*		theStack = [(WILDStackWindowController*)[[self window] windowController] cppStack];
//		int			hotSpotLeft = 0, hotSpotTop = 0;
//		std::string	cursorURL = theStack->GetDocument()->GetMediaURLByIDOfType( 128, EMediaTypeCursor, &hotSpotLeft, &hotSpotTop );
//		if( cursorURL.length() > 0 )
//		{
//			NSImage	*			cursorImage = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cursorURL.c_str()]]] autorelease];
//			NSCursor *			cursorInstance = [[NSCursor alloc] initWithImage: cursorImage hotSpot: NSMakePoint(hotSpotLeft,hotSpotTop)];
//			currentCursor = cursorInstance;
//		}
//	}
//	if( !currentCursor )
//		currentCursor = [NSCursor arrowCursor];
//	[self addCursorRect: [self bounds] cursor: currentCursor];
//}

@end


@implementation WILDStackWindowController

-(id)	initWithCppStack: (CStackMac*)inStack
{
	NSRect			wdBox = NSMakeRect(0,0,inStack->GetCardWidth(),inStack->GetCardHeight());
	NSWindow	*	theWindow = [[[NSWindow alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
	NSView*	cv = [[[WILDFlippedContentView alloc] initWithFrame: wdBox] autorelease];
	cv.wantsLayer = YES;
	[cv setLayerUsesCoreImageFilters: YES];
	theWindow.contentView = cv;
	[theWindow setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[theWindow setTitle: [NSString stringWithUTF8String: inStack->GetName().c_str()]];
	[theWindow setRepresentedURL: [NSURL URLWithString: [NSString stringWithUTF8String: inStack->GetURL().c_str()]]];
	[theWindow center];
	[theWindow setDelegate: self];

	self = [super initWithWindow: theWindow];
	if( self )
	{
		mStack = inStack;
	}
	
	return self;
}


-(void)	dealloc
{
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	
	[super dealloc];
}


-(void)	removeAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->DestroyView();
	}
	
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
}


-(void)	createAllViews
{
	[mBackgroundImageView removeFromSuperview];
	[mBackgroundImageView release];
	mBackgroundImageView = nil;
	[mCardImageView removeFromSuperview];
	[mCardImageView release];
	mCardImageView = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	CBackground	*	theBackground = theCard->GetBackground();
	std::string		bgPictureURL( theBackground->GetPictureURL() );
	if( theBackground->GetShowPicture() && bgPictureURL.length() > 0 )
	{
		mBackgroundImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
		[mBackgroundImageView setWantsLayer: YES];
		mBackgroundImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: bgPictureURL.c_str()]]] autorelease];
		[self.window.contentView addSubview: mBackgroundImageView];
	}
	
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBackground->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( self.window.contentView );
	}

	if( !theCard->GetStack()->GetEditingBackground() )
	{
		numParts = theCard->GetNumParts();
		std::string		cdPictureURL( theCard->GetPictureURL() );
		if( theCard->GetShowPicture() && cdPictureURL.length() > 0 )
		{
			mCardImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
			[mCardImageView setWantsLayer: YES];
			mCardImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cdPictureURL.c_str()]]] autorelease];
			[self.window.contentView addSubview: mCardImageView];
		}
		for( size_t x = 0; x < numParts; x++ )
		{
			CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
			if( !currPart )
				continue;
			currPart->CreateViewIn( self.window.contentView );
		}
	}
	
	[self drawBoundingBoxes];
}


-(void)	drawBoundingBoxes
{
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	CGColorSpaceRef	colorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );
	CGContextRef	bmContext = CGBitmapContextCreate( NULL, mStack->GetCardWidth(), mStack->GetCardHeight(), 8, mStack->GetCardWidth() * 8 * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little );
	CGColorSpaceRelease(colorSpace);
	NSGraphicsContext	*	cocoaContext = [NSGraphicsContext graphicsContextWithGraphicsPort: bmContext flipped: NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: cocoaContext];
	
	static NSColor	*	sPeekColor = nil;
	if( !sPeekColor )
		sPeekColor = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] retain];
	static NSColor	*	sSelectedColor = nil;
	if( !sSelectedColor )
		sSelectedColor = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_14"]] retain];
	[NSBezierPath setDefaultLineWidth: 1];
	
	size_t		cardHeight = mStack->GetCardHeight();
	
	CBackground	*	theBackground = theCard->GetBackground();
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*	currPart = theBackground->GetPart(x);
		if( currPart->IsSelected() )
		{
			[sSelectedColor set];
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}
		else if( mStack->GetPeeking() )
		{
			[sPeekColor set];
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}
	}

	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*	currPart = theCard->GetPart(x);
		if( currPart->IsSelected() )
		{
			[sSelectedColor set];
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}
		else if( mStack->GetPeeking() )
		{
			[sPeekColor set];
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}
	}

	mSelectionOverlay = [[CALayer alloc] init];
	[[self.window.contentView layer] addSublayer: mSelectionOverlay];
	[mSelectionOverlay setFrame: [self.window.contentView layer].frame];
	
	[NSGraphicsContext restoreGraphicsState];
	CGImageRef	bmImage = CGBitmapContextCreateImage( bmContext );
	mSelectionOverlay.contents = [(id)bmImage autorelease];
	
	CFRelease(bmContext);
}


-(Carlson::CStackMac*)	cppStack
{
	return mStack;
}


-(void)	saveDocument: (id)sender
{
	mStack->GetDocument()->Save();
}


-(void)	windowDidBecomeKey: (NSNotification *)notification
{
	CStack::SetFrontStack( mStack );
}


-(void)	windowDidBecomeMain: (NSNotification *)notification
{
	CStack::SetFrontStack( mStack );
}

@end
