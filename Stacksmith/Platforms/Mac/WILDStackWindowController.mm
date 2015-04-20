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
#include "CGraphicPart.h"
#include "CAlert.h"
#include "CCursor.h"
#import "ULIHighlightingButton.h"
#import "WILDCardInfoViewController.h"
#import "WILDBackgroundInfoViewController.h"
#import "WILDStackInfoViewController.h"
#import "UKHelperMacros.h"
#include "CRecentCardsList.h"


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


@interface WILDStackWindowController () <NSPopoverDelegate>

@end


@implementation WILDFlippedContentView

@synthesize stack = mStack;
@synthesize owningStackWindowController = mOwningStackWindowController;

-(BOOL)	isFlipped
{
	return YES;
}


-(NSView *)	hitTest: (NSPoint)aPoint
{
	NSView	*	hitView = [super hitTest: aPoint];
	bool	isEditing = mStack ? (mStack->GetTool() != EBrowseTool && mStack->GetTool() != EEditTextTool) : false;
	bool	isPeeking = mStack ? mStack->GetPeeking() : false;
	if( (isEditing || isPeeking) && hitView != nil )
		return self;
	return hitView;
}


-(void)	rightMouseDown: (NSEvent*)theEvt
{
	[self handleMouseEvent: theEvt];
}


-(void)	otherMouseDown: (NSEvent*)theEvt
{
	[self handleMouseEvent: theEvt];
}


-(void)	mouseDown: (NSEvent*)theEvt
{
	[self handleMouseEvent: theEvt];
}


-(void)	handleMouseEvent: (NSEvent*)theEvt
{
	TTool		currentTool = mStack->GetTool();
	bool		isEditing = currentTool == EPointerTool;
	bool		isPeeking = mStack->GetPeeking();
	CScriptableObject	*hitObject = NULL;
	CCard	*	theCard = mStack->GetCurrentCard();
	const char*	dragMessage = NULL, *upMessage = NULL, *doubleUpMessage = NULL;
	NSPoint		hitPos = [self convertPoint: [theEvt locationInWindow] fromView: nil];
	LEOInteger	customPartIndex = EAllHandlesSelected;
	
	if( currentTool != EBrowseTool || isPeeking )
	{
		bool		shiftKeyDown = [theEvt modifierFlags] & NSShiftKeyMask;
		size_t		numParts = 0;
		CPart*		hitPart = NULL;
		
		// Find what was clicked:
		if( !mStack->GetEditingBackground() )
		{
			numParts = theCard->GetNumParts();
			for( size_t x = numParts; x > 0 && hitPart == nullptr; x-- )
			{
				CPart	*	thePart = theCard->GetPart( x-1 );
				if( !hitPart && thePart->CanBeEditedWithTool(currentTool) && thePart->HitTestForEditing( hitPos.x, hitPos.y, thePart->IsSelected() ? EHitTestHandlesToo : EHitTestWithoutHandles, &customPartIndex ) != ENothingHitPart )
				{
					hitPart = thePart;
				}
			}
		}
		
		numParts = theCard->GetBackground()->GetNumParts();
		for( size_t x = numParts; x > 0 && hitPart == nullptr; x-- )
		{
			CPart	*	thePart = theCard->GetBackground()->GetPart( x-1 );
			if( !hitPart && thePart->CanBeEditedWithTool(currentTool) && thePart->HitTestForEditing( hitPos.x, hitPos.y, thePart->IsSelected() ? EHitTestHandlesToo : EHitTestWithoutHandles, &customPartIndex ) != ENothingHitPart )
			{
				hitPart = thePart;
			}
		}
		
		// Deselect all other background parts:
		if( (isEditing || hitPart) && !isPeeking )
		{
			numParts = theCard->GetBackground()->GetNumParts();
			for( size_t x = numParts; x > 0; x-- )
			{
				CPart	*	thePart = theCard->GetBackground()->GetPart( x-1 );
				if( thePart != hitPart )
				{
					if( !hitPart || (!shiftKeyDown && !hitPart->IsSelected()) )
						thePart->SetSelected(false);
				}
			}

			if( !mStack->GetEditingBackground() )
			{
				numParts = theCard->GetNumParts();
				for( size_t x = numParts; x > 0; x-- )
				{
					CPart	*	thePart = theCard->GetPart( x-1 );
					if( thePart != hitPart )
					{
						if( !hitPart || (!shiftKeyDown && !hitPart->IsSelected()) )
							thePart->SetSelected(false);
					}
				}
			}
		}
		
		const char*	mouseDownMessage = NULL;
		const char*	mouseDoubleDownMessage = NULL;
		
		if( isPeeking )
		{
			mouseDownMessage = "mouseDownWhilePeeking %ld";
			mouseDoubleDownMessage = "mouseDoubleDownWhilePeeking %ld";
			dragMessage = "mouseDragWhilePeeking %ld";
			upMessage = "mouseUpWhilePeeking %ld";
			doubleUpMessage = "mouseDoubleClickWhilePeeking %ld";
		}
		else if( isEditing || hitPart )
		{
			mouseDownMessage = "mouseDownWhileEditing %ld";
			mouseDoubleDownMessage = "mouseDoubleDownWhileEditing %ld";
			dragMessage = "mouseDragWhileEditing %ld";
			upMessage = "mouseUpWhileEditing %ld";
			doubleUpMessage = "mouseDoubleClickWhileEditing %ld";
		}
		
		if( !hitPart )
		{
			if( mouseDownMessage )
			{
				CAutoreleasePool	cppPool;
				theCard->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?mouseDownMessage:mouseDoubleDownMessage, [theEvt buttonNumber] +1 );
			}
			hitObject = theCard;
		}
		else
		{
			if( !isPeeking )
			{
				if( !hitPart->IsSelected() )
					hitPart->SetSelected(true);
				else if( hitPart->IsSelected() && customPartIndex != -1 )
					hitPart->SetSelected(true, customPartIndex);
				else if( hitPart->IsSelected() && shiftKeyDown )
					hitPart->SetSelected(false);
			}
			if( mouseDownMessage )
			{
				CAutoreleasePool	cppPool;
				hitPart->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?mouseDownMessage:mouseDoubleDownMessage, [theEvt buttonNumber] +1 );
			}
			hitObject = hitPart;
		}
	}
	
	if( currentTool == EBrowseTool )
	{
		[self.window makeFirstResponder: self];
		hitObject = theCard;
		
		dragMessage = "mouseDrag %ld";
		upMessage = "mouseUp %ld";
		doubleUpMessage = "mouseDoubleClick %ld";
		
		CAutoreleasePool		pool;
		theCard->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?"mouseDown":"mouseDoubleDown", [theEvt buttonNumber] +1 );
	}
	else if( currentTool == EOvalTool && hitObject == theCard )
	{
		CLayer		*	owner = mStack->GetCurrentLayer();
		CGraphicPart*	thePart = (CGraphicPart*) CPart::GetPartCreatorForType("graphic")->NewPartInOwner( owner );
		thePart->SetID( owner->GetUniqueIDForPart() );
		thePart->SetRect( hitPos.x, hitPos.y, hitPos.x, hitPos.y );
		thePart->SetStyle(EGraphicStyleOval);
		owner->AddPart(thePart);
		thePart->Release();
		thePart->IncrementChangeCount();
		[mOwningStackWindowController refreshExistenceAndOrderOfAllViews];
		thePart->SetSelected(true,customPartIndex);
		hitObject = thePart;
	}
	else if( currentTool == ERectangleTool && hitObject == theCard )
	{
		CLayer		*	owner = mStack->GetCurrentLayer();
		CGraphicPart*	thePart = (CGraphicPart*) CPart::GetPartCreatorForType("graphic")->NewPartInOwner( owner );
		thePart->SetID( owner->GetUniqueIDForPart() );
		thePart->SetRect( hitPos.x, hitPos.y, hitPos.x, hitPos.y );
		thePart->SetStyle(EGraphicStyleRectangle);
		owner->AddPart(thePart);
		thePart->Release();
		thePart->IncrementChangeCount();
		[mOwningStackWindowController refreshExistenceAndOrderOfAllViews];
		thePart->SetSelected(true,customPartIndex);
		hitObject = thePart;
	}
	else if( currentTool == ERoundrectTool && hitObject == theCard )
	{
		CLayer		*	owner = mStack->GetCurrentLayer();
		CGraphicPart*	thePart = (CGraphicPart*) CPart::GetPartCreatorForType("graphic")->NewPartInOwner( owner );
		thePart->SetID( owner->GetUniqueIDForPart() );
		thePart->SetRect( hitPos.x, hitPos.y, hitPos.x, hitPos.y );
		thePart->SetStyle(EGraphicStyleRoundrect);
		owner->AddPart(thePart);
		thePart->Release();
		thePart->IncrementChangeCount();
		[mOwningStackWindowController refreshExistenceAndOrderOfAllViews];
		thePart->SetSelected(true,customPartIndex);
		hitObject = thePart;
	}
	else if( currentTool == ELineTool && hitObject == theCard )
	{
		CLayer		*	owner = mStack->GetCurrentLayer();
		CGraphicPart*	thePart = (CGraphicPart*) CPart::GetPartCreatorForType("graphic")->NewPartInOwner( owner );
		thePart->SetID( owner->GetUniqueIDForPart() );
		thePart->SetRect( 0, 0, mStack->GetCardWidth(), mStack->GetCardHeight() );
		thePart->SetStyle(EGraphicStyleLine);
		owner->AddPart(thePart);
		LEONumber	pressure = theEvt.pressure;
		if( pressure <= 0 )
			pressure = 1;
		thePart->AddPoint( hitPos.x, hitPos.y, pressure * mStack->GetLineSize() );	// Start point of line. +++ Only works cuz we know the part rect is at 0,0.
		thePart->AddPoint( hitPos.x, hitPos.y, pressure * mStack->GetLineSize() );	// End point of line which we update while tracking. +++ Only works cuz we know the part rect is at 0,0.
		thePart->Release();
		thePart->IncrementChangeCount();
		[mOwningStackWindowController refreshExistenceAndOrderOfAllViews];
		thePart->SetSelected(true,customPartIndex);
		hitObject = thePart;
	}
	else if( currentTool == EBezierPathTool && hitObject == theCard )
	{
		CLayer		*	owner = mStack->GetCurrentLayer();
		CGraphicPart*	thePart = (CGraphicPart*) CPart::GetPartCreatorForType("graphic")->NewPartInOwner( owner );
		thePart->SetID( owner->GetUniqueIDForPart() );
		thePart->SetRect( 0, 0, mStack->GetCardWidth(), mStack->GetCardHeight() );
		thePart->SetStyle(EGraphicStyleBezierPath);
		owner->AddPart(thePart);
		LEONumber	pressure = theEvt.pressure;
		if( pressure <= 0 )
			pressure = 1;
		thePart->AddPoint( hitPos.x, hitPos.y, pressure * mStack->GetLineSize() );	// Start point of line. +++ Only works cuz we know the part rect is at 0,0.
		thePart->Release();
		thePart->IncrementChangeCount();
		[mOwningStackWindowController refreshExistenceAndOrderOfAllViews];
		thePart->SetSelected(true,customPartIndex);
		hitObject = thePart;
	}
	else if( hitObject != theCard )
	{
		const char*	mouseDownMessage = "mouseDownWhileEditing %ld";
		const char*	mouseDoubleDownMessage = "mouseDoubleDownWhileEditing %ld";
		dragMessage = "mouseDragWhileEditing %ld";
		upMessage = "mouseUpWhileEditing %ld";
		doubleUpMessage = "mouseDoubleClickWhileEditing %ld";

		CAutoreleasePool	cppPool;
		((CPart*)hitObject)->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?mouseDownMessage:mouseDoubleDownMessage, [theEvt buttonNumber] +1 );
	}
		
	[mOwningStackWindowController drawBoundingBoxes];

	CCursor::Grab( (int)theEvt.buttonNumber, [theEvt,hitObject,currentTool,dragMessage,self]( LEONumber screenX, LEONumber screenY, LEONumber pressure )
	{
		LEONumber	x = screenX -self.window.frame.origin.x;
		LEONumber	y = screenY -(self.window.screen.frame.size.height -NSMaxY([self.window contentRectForFrameRect: self.window.frame]));
		if( dragMessage )
		{
			CAutoreleasePool	cppPool;
			hitObject->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, dragMessage, [theEvt buttonNumber] +1 );
		}
		else if( currentTool == ELineTool )
		{
			CGraphicPart*thePart = (CGraphicPart*)hitObject;
			if( pressure <= 0 )	// 0 *while* dragging without a mouse up? The pointing device probably can't report pressure.
				pressure = 1.0;
			thePart->UpdateLastPoint( x, y, pressure * mStack->GetLineSize() );	// +++ Only works cuz we know the part rect is at 0,0.
		}
		else if( currentTool == EBezierPathTool )
		{
			CGraphicPart*thePart = (CGraphicPart*)hitObject;
			if( pressure <= 0 )	// 0 *while* dragging without a mouse up? The pointing device probably can't report pressure.
				pressure = 1.0;
			thePart->AddPoint( x, y, pressure * mStack->GetLineSize() );	// +++ Only works cuz we know the part rect is at 0,0.
		}
		else
		{
			CPart*thePart = (CPart*)hitObject;
			thePart->SetRect( thePart->GetLeft(), thePart->GetTop(), x, y );
		}
		
		return true;
	} );
	
	if( upMessage )
	{
		CAutoreleasePool	cppPool;
		hitObject->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?upMessage:doubleUpMessage, [theEvt buttonNumber] +1 );
	}
	else if( currentTool == ELineTool || currentTool == EBezierPathTool )
	{
		((CGraphicPart*)hitObject)->SizeToFit();	// Pull part rect snugly around the actual drawing.
	}
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
	CCard *				theCard = mStack->GetCurrentCard();
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
	
	std::function<void(const char *, size_t, size_t, CScriptableObject *)>	errHandler = [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); };
	
	{
		CAutoreleasePool		pool;
		theCard->SendMessage( NULL, errHandler, "keyDown %s,%s,%s,%s,%s", [[theEvent characters] UTF8String], firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	
	if( theEvent.charactersIgnoringModifiers.length > 0 )
	{
		CAutoreleasePool		pool;
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
//		int			hotSpotLeft = 0, hotSpotTop = 0;
//		std::string	cursorURL = mStack->GetDocument()->GetMediaURLByIDOfType( 128, EMediaTypeCursor, &hotSpotLeft, &hotSpotTop );
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
	self = [super initWithWindowNibName: @""];
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
	[mPopover release];
	mPopover = nil;
	[mContentView release];
	mContentView = nil;
	
	[super dealloc];
}


-(void)	loadWindow
{
	[self updateStyle];
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

	CBackground	*	theBg = theCard->GetBackground();
	numParts = theBg->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBg->GetPart(x));
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
	
	if( !mContentView )
	{
		mContentView = [[WILDFlippedContentView alloc] initWithFrame: NSMakeRect(0, 0, mStack->GetCardWidth(), mStack->GetCardHeight())];
		mContentView.stack = mStack;
		mContentView.owningStackWindowController = self;
		mContentView.wantsLayer = YES;
		[mContentView setLayerUsesCoreImageFilters: YES];
	}
	else
	{
		NSRect		box = [mContentView frame];
		box.size = NSMakeSize(mStack->GetCardWidth(), mStack->GetCardHeight() );
		[mContentView setFrame: box];
	}
	
	CBackground	*	theBackground = theCard->GetBackground();
	std::string		bgPictureURL( theBackground->GetPictureURL() );
	if( theBackground->GetShowPicture() && bgPictureURL.length() > 0 )
	{
		mBackgroundImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
		[mBackgroundImageView setImageAlignment: NSImageAlignTopLeft];
		[mBackgroundImageView setImageScaling: NSImageScaleNone];
		[mBackgroundImageView setWantsLayer: YES];
		mBackgroundImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: bgPictureURL.c_str()]]] autorelease];
		[mContentView addSubview: mBackgroundImageView];
	}
	
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBackground->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( mContentView );
	}

	if( !theCard->GetStack()->GetEditingBackground() )
	{
		numParts = theCard->GetNumParts();
		std::string		cdPictureURL( theCard->GetPictureURL() );
		if( theCard->GetShowPicture() && cdPictureURL.length() > 0 )
		{
			mCardImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
			[mCardImageView setImageAlignment: NSImageAlignTopLeft];
			[mCardImageView setImageScaling: NSImageScaleNone];
			[mCardImageView setWantsLayer: YES];
			mCardImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cdPictureURL.c_str()]]] autorelease];
			[mContentView addSubview: mCardImageView];
		}
		for( size_t x = 0; x < numParts; x++ )
		{
			CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
			if( !currPart )
				continue;
			currPart->CreateViewIn( mContentView );
		}
	}
	
	[self drawBoundingBoxes];
}


-(void)	refreshExistenceAndOrderOfAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;

	CBackground	*	theBg = theCard->GetBackground();
	size_t			numParts = theBg->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBg->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( mContentView );
	}
	
	if( !mStack->GetEditingBackground() )
	{
		numParts = theCard->GetNumParts();
		for( size_t x = 0; x < numParts; x++ )
		{
			CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
			if( !currPart )
				continue;
			currPart->CreateViewIn( mContentView );
		}
	}
}


-(void)	drawOneBoundingBox: (CPart*)currPart
{
	static NSColor	*	sPeekColor = nil;
	if( !sPeekColor )
		sPeekColor = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] retain];
	static NSColor	*	sSelectedColor = nil;
	if( !sSelectedColor )
		sSelectedColor = [[NSColor colorWithCalibratedRed: 0.102 green: 0.180 blue: 0.998 alpha: 1.000] retain];
	static NSColor	*	sUnselectedColor = nil;
	if( !sUnselectedColor )
		sUnselectedColor = [[NSColor colorWithCalibratedRed:0.682 green:0.805 blue:0.999 alpha:1.000] retain];
	static NSColor	*	sSelectedBorderColor = nil;
	if( !sSelectedBorderColor )
		sSelectedBorderColor = [[sSelectedColor blendedColorWithFraction: 0.2 ofColor: NSColor.blackColor] retain];
	
	size_t	cardHeight = mStack->GetCardHeight();
	NSRect	partRect = NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 );
	NSRectFillUsingOperation( partRect, NSCompositeClear );
	if( mStack->GetPeeking() || (currPart->IsSelected() && currPart->GetNumCustomHandlesForTool( mStack->GetTool() ) <= 0) )
	{
		[sPeekColor set];
		[NSBezierPath strokeRect: partRect];
	}
	if( currPart->IsSelected() )
	{
		[sSelectedColor setFill];
		[sSelectedBorderColor setStroke];
		
		LEOInteger	numCustomHandles = currPart->GetNumCustomHandlesForTool( mStack->GetTool() );
		if( numCustomHandles >= 0 )
		{
			LEOInteger		selectedHandle = currPart->GetSelectedHandle();
			for( LEOInteger x = 0; x < numCustomHandles; x++ )
			{
				LEONumber	l, t, r, b;
				currPart->GetRectForCustomHandle( x, &l, &t, &r, &b );
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				if( selectedHandle == EAllHandlesSelected || selectedHandle == x )
				{
					[sUnselectedColor setFill];
				}
				NSRectFill(grabby);
				if( selectedHandle == EAllHandlesSelected || selectedHandle == x )
				{
					[sSelectedColor setFill];
				}
				[NSBezierPath strokeRect: grabby];
			}
		}
		else
		{
			LEONumber	l, t, r, b;
			if( currPart->GetRectForHandle( ELeftGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ELeftGrabberHitPart | ETopGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ETopGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ERightGrabberHitPart | ETopGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ERightGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ERightGrabberHitPart | EBottomGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( EBottomGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
			if( currPart->GetRectForHandle( ELeftGrabberHitPart | EBottomGrabberHitPart, &l, &t, &r, &b ) )
			{
				NSRect		grabby = NSMakeRect(l +0.5, cardHeight -b +0.5, r -l -1.0, b -t -1.0 );
				NSRectFill(grabby);
				[NSBezierPath strokeRect: grabby];
			}
		}
	}
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
	
	CBackground	*	theBackground = theCard->GetBackground();
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*	currPart = theBackground->GetPart(x);
		[self drawOneBoundingBox: currPart];
	}

	if( !mStack->GetEditingBackground() )
	{
		numParts = theCard->GetNumParts();
		for( size_t x = 0; x < numParts; x++ )
		{
			CPart*	currPart = theCard->GetPart(x);
			[self drawOneBoundingBox: currPart];
		}
	}

	NSBezierPath*	linePath = [NSBezierPath bezierPath];
	NSSize	cardSize = [mContentView layer].frame.size;
	size_t	numGuidelines = mStack->GetNumGuidelines();
	for( size_t x = 0; x < numGuidelines; x++ )
	{
		long long		coord = 0LL;
		bool			horzNotVert = false;
		mStack->GetGuidelineAtIndex( x, &coord, &horzNotVert );
		if( horzNotVert )
		{
			[linePath moveToPoint: NSMakePoint(0,cardSize.height -coord +0.5)];
			[linePath lineToPoint: NSMakePoint(cardSize.width,cardSize.height -coord +0.5)];
		}
		else
		{
			[linePath moveToPoint: NSMakePoint(coord +0.5,0)];
			[linePath lineToPoint: NSMakePoint(coord +0.5,cardSize.height)];
		}
	}
	[NSColor.blueColor set];
	CGFloat	pattern[2] = { 4.0, 1.0 };
	[linePath setLineDash: pattern count: sizeof(pattern) / sizeof(CGFloat) phase: 0.0];
	[linePath stroke];
	
	if( !mSelectionOverlay )
		mSelectionOverlay = [[CALayer alloc] init];
	[[mContentView layer] addSublayer: mSelectionOverlay];
	[mSelectionOverlay setFrame: [mContentView layer].frame];
	
	[NSGraphicsContext restoreGraphicsState];
	CGImageRef	bmImage = CGBitmapContextCreateImage( bmContext );
	mSelectionOverlay.contents = [(id)bmImage autorelease];
	
	CFRelease(bmContext);
}


-(void)	updateStyle
{
	NSRect			wdBox = NSMakeRect(0,0,mStack->GetCardWidth(),mStack->GetCardHeight());
	NSWindow	*	prevWindow = nil;
	if( mWasVisible && !mPopover )
	{
		prevWindow = [self.window retain];
		wdBox = [prevWindow contentRectForFrameRect: prevWindow.frame];
	}
	
	TStackStyle		theStyle = mStack->GetStyle();
	switch( theStyle )
	{
		case EStackStyleStandard:
			self.window = [[[NSWindow alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | (mStack->IsResizable() ? NSResizableWindowMask : 0) backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
			break;
		
		case EStackStyleRectangle:
			self.window = [[[NSWindow alloc] initWithContentRect: wdBox styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setStyleMask: NSBorderlessWindowMask];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenAuxiliary];
			break;
		
		case EStackStylePalette:
			self.window = [[[NSPanel alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | (mStack->IsResizable() ? NSResizableWindowMask : 0) | NSUtilityWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenAuxiliary];
			[(NSPanel*)self.window setFloatingPanel: YES];
			break;
		
		case EStackStylePopup:
			self.window = [[[NSWindow alloc] initWithContentRect: NSMakeRect(wdBox.origin.x,wdBox.origin.y,10,10) styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setBackgroundColor: NSColor.redColor];
			//[self.window setLevel: NSFloatingWindowLevel];
			[self.window setAlphaValue: 0.0];
			break;
	}
	
	if( !mContentView )
	{
		NSRect		box = { NSZeroPoint, { (CGFloat)mStack->GetCardWidth(), (CGFloat)mStack->GetCardHeight() } };
		mContentView = [[WILDFlippedContentView alloc] initWithFrame: box];
		mContentView.stack = mStack;
		mContentView.owningStackWindowController = self;
		mContentView.wantsLayer = YES;
		[mContentView setLayerUsesCoreImageFilters: YES];
	}
	if( theStyle == EStackStylePopup )
	{
		mPopover = [[NSPopover alloc] init];
		mPopover.delegate = self;
		mPopover.contentSize = wdBox.size;
		NSViewController*	nsvc = [[[NSViewController alloc] init] autorelease];
		nsvc.view = mContentView;
		mPopover.contentViewController = nsvc;
	}
	else
	{
        @try
        {
			self.window.contentView = mContentView;
			[self.window setTitle: [NSString stringWithUTF8String: mStack->GetName().c_str()]];
			[self.window setRepresentedURL: [NSURL URLWithString: [NSString stringWithUTF8String: mStack->GetURL().c_str()]]];
        }
        @catch( NSException* err )
        {
            UKLog(@"Exception caught: %@", err);
        }
	}
	NSDisableScreenUpdates();
	if( !prevWindow )
		[self.window center];
	[self.window setDelegate: self];
	if( mWasVisible )
		[self.window orderFront: self];
	if( theStyle == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
	else
	{
		[mPopover close];
		[mPopover release];
		mPopover = nil;
	}
	[prevWindow release];
	NSEnableScreenUpdates();
}


-(void)	showWindow: (id)sender
{
	[super showWindow: sender];
	if( mStack->GetStyle() == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
	mWasVisible = YES;
}


-(void)	showWindowOverPart: (CPart*)overPart
{
	[super showWindow: nil];
	if( mStack->GetStyle() == EStackStylePopup )
	{
		CMacPartBase	*	thePart = dynamic_cast<CMacPartBase*>(overPart);
		NSView			*	theView = thePart ? thePart->GetView() : self.window.contentView;
		[mPopover setBehavior: NSPopoverBehaviorTransient];
		[mPopover showRelativeToRect: theView.bounds ofView: theView preferredEdge: NSMaxYEdge];
	}
	mWasVisible = YES;
}


-(void)	showContextualMenuForSelection
{
	NSMenu*	contextMenu = [[NSMenu alloc] initWithTitle: @"Part Actions"];
	
	[[contextMenu addItemWithTitle: @"Get Info…" action: @selector(showPartInfoWindow:) keyEquivalent: @""] setTarget: self];
	
	[contextMenu popUpMenuPositioningItem: nil atLocation: [NSEvent mouseLocation] inView: nil];
	
	[contextMenu release];
}


-(IBAction)	showPartInfoWindow: (id)sender
{
	CCard*	theCard = mStack->GetCurrentCard();
	size_t	numParts = theCard->GetNumParts();
	BOOL	foundOne = false;
	
	if( !mStack->GetEditingBackground() )
	{
		for( size_t x = numParts; x > 0 && !foundOne; x-- )
		{
			CPart*	currPart = theCard->GetPart(x -1);
			if( currPart->IsSelected() )
			{
				mStack->ShowPropertyEditorForObject( currPart );
				foundOne = true;
			}
		}
	}
	
	CBackground* theLayer = theCard->GetBackground();
	numParts = theLayer->GetNumParts();
	for( size_t x = numParts; x > 0 && !foundOne; x-- )
	{
		CPart*	currPart = theLayer->GetPart(x -1);
		if( currPart->IsSelected() )
		{
			mStack->ShowPropertyEditorForObject( currPart );
			foundOne = true;
		}
	}
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
	mWasVisible = YES;
	mStack->SetVisible(true);
	
	if( mStack->GetStyle() == EStackStylePopup )
	{
		@try
		{
			[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
		}
		@catch( NSException* err )
		{
			NSLog(@"error opening stack window %@",err);
		}
	}
}


-(void)	windowDidBecomeMain: (NSNotification *)notification
{
	CStack::SetFrontStack( mStack );
	mWasVisible = YES;
	mStack->SetVisible(true);
	
	if( mStack->GetStyle() == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
}


-(void)	windowWillClose: (NSNotification *)notification
{
	if( mStack->GetNeedsToBeSaved() )
		mStack->GetDocument()->Save();
	
	mWasVisible = NO;
	mStack->SetVisible(false);
}


-(void)	windowDidResize: (NSNotification *)notification
{
	NSRect	newBox = [self.window contentRectForFrameRect: self.window.frame];
	mStack->SetCardWidth( newBox.size.width );
	mStack->SetCardHeight( newBox.size.height );
}


-(void)	popoverWillShow: (NSNotification *)notification
{
	if( notification.object == mPopover )
		;
}


-(void)	popoverDidShow: (NSNotification *)notification
{
	if( notification.object == mPopover )
	{
		CStack::SetFrontStack( mStack );
		mWasVisible = YES;
		mStack->SetVisible(true);
	}
}


-(void)	popoverWillClose: (NSNotification *)notification
{
	if( notification.object == mPopover )
	{
		mWasVisible = NO;
		mStack->SetVisible(false);
	}
}


-(IBAction)	showCardInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDCardInfoViewController*	cardInfo = [[[WILDCardInfoViewController alloc] initWithCard: mStack->GetCurrentCard()] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: cardInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showBackgroundInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDBackgroundInfoViewController*	backgroundInfo = [[[WILDBackgroundInfoViewController alloc] initWithBackground: mStack->GetCurrentCard()->GetBackground()] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: backgroundInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showStackInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDStackInfoViewController*	stackInfo = [[[WILDStackInfoViewController alloc] initWithStack: mStack] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: stackInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}


-(IBAction)	toggleBackgroundEditMode: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetEditingBackground( !mStack->GetEditingBackground() );
}


-(IBAction)	goBack: (id)sender
{
	CAutoreleasePool	pool;
	CCardRef	theCard = CRecentCardsList::GetSharedInstance()->PopCard();
	theCard->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } );
}


-(IBAction)	goFirstCard: (id)sender
{
	CAutoreleasePool	pool;
	CCardRef	oldCard = mStack->GetCurrentCard();
	if( mStack->GetCard(0)->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } ) )
		CRecentCardsList::GetSharedInstance()->AddCard( oldCard );
}


-(IBAction)	goPrevCard: (id)sender
{
	CAutoreleasePool	pool;
	CCardRef	oldCard = mStack->GetCurrentCard();
	if( mStack->GetPreviousCard()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } ) )
		CRecentCardsList::GetSharedInstance()->AddCard( oldCard );
}


-(IBAction)	goNextCard: (id)sender
{
	CAutoreleasePool	pool;
	CCardRef	oldCard = mStack->GetCurrentCard();
	if( mStack->GetNextCard()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } ) )
		CRecentCardsList::GetSharedInstance()->AddCard( oldCard );
}


-(IBAction)	goLastCard: (id)sender
{
	CAutoreleasePool	pool;
	CCardRef	oldCard = mStack->GetCurrentCard();
	if( mStack->GetCard(mStack->GetNumCards() -1)->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } ) )
		CRecentCardsList::GetSharedInstance()->AddCard( oldCard );
}


-(BOOL)	validateMenuItem: (NSMenuItem*)theItem
{
	if( theItem.action == @selector(delete:) )
	{
		return( mStack->GetTool() != EBrowseTool && mStack->GetCurrentLayer()->CanDeleteSelectedItem() );
	}
	else if( theItem.action == @selector(copy:) )
	{
		return( mStack->GetTool() != EBrowseTool && mStack->GetCurrentLayer()->CanCopySelectedItem() );
	}
	else if( theItem.action == @selector(paste:) )
	{
		return( mStack->GetTool() != EBrowseTool && [[NSPasteboard generalPasteboard] availableTypeFromArray: @[ @"com.the-void-software.stacksmith.parts.xml" ]] != nil );
	}
	else if( theItem.action == @selector(deleteCard:) )
	{
		return( mStack->GetNumCards() > 1 && !mStack->GetCurrentCard()->GetCantDelete() );
	}
	else if( theItem.action == @selector(deleteStack:) )
	{
		return( mStack->GetDocument()->GetNumStacks() > 1 && !mStack->GetCantDelete() );
	}
	else if( theItem.action == @selector(goBack:) )
	{
		return CRecentCardsList::GetSharedInstance()->PeekCard() != NULL;
	}
	else if( theItem.action == @selector(toggleBackgroundEditMode:) )
	{
		[theItem setState: mStack->GetEditingBackground() ? NSOnState : NSOffState];
		return YES;
	}
	else if( theItem.action == @selector(saveDocument:) )
	{
		return mStack->GetDocument()->GetNeedsToBeSaved() && !mStack->GetDocument()->IsWriteProtected();
	}
	else
		return [self respondsToSelector: theItem.action];
}


-(IBAction)	delete: (id)sender
{
	if( mStack->GetTool() != EBrowseTool )
	{
		CAutoreleasePool	pool;
		mStack->GetCurrentLayer()->DeleteSelectedItem();
		[self drawBoundingBoxes];
	}
}


-(IBAction)	copy: (id)sender
{
	if( mStack->GetTool() != EBrowseTool )
	{
		CAutoreleasePool	pool;
		std::string	xml = mStack->GetCurrentLayer()->CopySelectedItem();
		NSPasteboard*	pb = [NSPasteboard generalPasteboard];
		[pb clearContents];
		[pb addTypes: @[ @"com.the-void-software.stacksmith.parts.xml" ] owner: nil];
		[pb setString: [NSString stringWithUTF8String: xml.c_str()] forType: @"com.the-void-software.stacksmith.parts.xml"];
	}
}


-(IBAction)	paste: (id)sender
{
	if( mStack->GetTool() == EBrowseTool )
	{
		CAutoreleasePool	pool;
		NSPasteboard*	pb = [NSPasteboard generalPasteboard];
		NSString*		xmlStr = [pb stringForType: @"com.the-void-software.stacksmith.parts.xml"];
		mStack->DeselectAllObjectsOnCard();
		mStack->DeselectAllObjectsOnBackground();
		std::vector<CPartRef>	newParts = mStack->GetCurrentLayer()->PasteObject( std::string(xmlStr.UTF8String) );
		[self refreshExistenceAndOrderOfAllViews];
		for( CPart* thePart : newParts )
			thePart->SetSelected(true);
		[self drawBoundingBoxes];
	}
}


-(IBAction)	deleteCard: (id)sender
{
	CAutoreleasePool	pool;
	mStack->DeleteCard( mStack->GetCurrentCard() );
}


-(IBAction)	deleteStack: (id)sender
{
	CAutoreleasePool	pool;
	mStack->GetDocument()->DeleteStack( mStack );
}


-(IBAction)	takeToolFromTag: (id)sender
{
	mStack->SetTool( (TTool) [sender tag] );
}


-(BOOL)	validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)sender
{
	if( [sender action] == @selector(takeToolFromTag:) )
	{
		if( [sender tag] == mStack->GetTool() )
			[(NSButton*)sender setState: NSOnState];
		else
			[(NSButton*)sender setState: NSOffState];
		return YES;
	}
	else if( sender.action == @selector(toggleBackgroundEditMode:) )
	{
		[(NSButton*)sender setState: mStack->GetEditingBackground() ? NSOnState : NSOffState];
		return YES;
	}
	else
		return [self respondsToSelector: sender.action];
}


-(IBAction)	newStack: (id)sender
{
	CAutoreleasePool	pool;
	mStack->GetDocument()->AddNewStack()->GoThereInNewWindow( EOpenInNewWindow, mStack, NULL, [](){  } );
}


-(IBAction)	newCard: (id)sender
{
	CAutoreleasePool	pool;
	mStack->AddNewCard()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } );
}


-(IBAction)	newBackground: (id)sender
{
	CAutoreleasePool	pool;
	mStack->AddNewCardWithBackground()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL, [](){  } );
}


-(IBAction)	newButton: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetTool(EPointerTool);
	CLayer	*	owner = mStack->GetCurrentLayer();
	CPart	*	thePart = CPart::GetPartCreatorForType("button")->NewPartInOwner( owner );
	thePart->SetID( owner->GetUniqueIDForPart() );
	owner->AddPart(thePart);
	thePart->Release();
	thePart->IncrementChangeCount();
	[self refreshExistenceAndOrderOfAllViews];
	thePart->SetSelected(true);
}


-(IBAction)	newField: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetTool(EPointerTool);
	CLayer	*	owner = mStack->GetCurrentLayer();
	CPart	*	thePart = CPart::GetPartCreatorForType("field")->NewPartInOwner( owner );
	thePart->SetID( owner->GetUniqueIDForPart() );
	owner->AddPart(thePart);
	thePart->Release();
	thePart->IncrementChangeCount();
	[self refreshExistenceAndOrderOfAllViews];
	thePart->SetSelected(true);
}


-(IBAction)	newMoviePlayer: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetTool(EPointerTool);
	CLayer	*	owner = mStack->GetCurrentLayer();
	CPart	*	thePart = CPart::GetPartCreatorForType("moviePlayer")->NewPartInOwner( owner );
	thePart->SetID( owner->GetUniqueIDForPart() );
	owner->AddPart(thePart);
	thePart->Release();
	thePart->IncrementChangeCount();
	[self refreshExistenceAndOrderOfAllViews];
	thePart->SetSelected(true);
}


-(IBAction)	newWebBrowser: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetTool(EPointerTool);
	CLayer	*	owner = mStack->GetCurrentLayer();
	CPart	*	thePart = CPart::GetPartCreatorForType("browser")->NewPartInOwner( owner );
	thePart->SetID( owner->GetUniqueIDForPart() );
	owner->AddPart(thePart);
	thePart->Release();
	thePart->IncrementChangeCount();
	[self refreshExistenceAndOrderOfAllViews];
	thePart->SetSelected(true);
}


-(IBAction)	newTimer: (id)sender
{
	CAutoreleasePool	pool;
	mStack->SetTool(EPointerTool);
	CLayer	*	owner = mStack->GetCurrentLayer();
	CPart	*	thePart = CPart::GetPartCreatorForType("timer")->NewPartInOwner( owner );
	thePart->SetID( owner->GetUniqueIDForPart() );
	owner->AddPart(thePart);
	thePart->Release();
	thePart->IncrementChangeCount();
	[self refreshExistenceAndOrderOfAllViews];
	thePart->SetSelected(true);
}


-(NSData*)	currentCardSnapshotData
{
	NSRect		wdBox = [mContentView.window contentRectForFrameRect: mContentView.window.frame];
	if( NSScreen.screens.count > 0 )
		wdBox.origin.y = [NSScreen.screens[0] frame].size.height -NSMaxY(wdBox);	// Flip rect, CGRect is upper-left relative for this API.
	CGImageRef	img = CGWindowListCreateImage( wdBox, kCGWindowListOptionIncludingWindow, (int)mContentView.window.windowNumber, kCGWindowImageBoundsIgnoreFraming | kCGWindowImageBestResolution );
	NSBitmapImageRep*	bir = [[[NSBitmapImageRep alloc] initWithCGImage: img] autorelease];
	CGImageRelease( img );
	return [bir representationUsingType: NSJPEGFileType properties: @{}];
	//return [mContentView dataWithPDFInsideRect: [mContentView bounds]];
}


-(NSUInteger) validModesForFontPanel: (NSFontPanel *) fontPanel
{
	return NSFontPanelFaceModeMask | NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask | NSFontPanelUnderlineEffectModeMask | NSFontPanelStrikethroughEffectModeMask | NSFontPanelTextColorEffectModeMask;
}


-(void)	changeFont: (NSFontManager*)sender
{
	CAutoreleasePool	pool;
	CLayer		*	owner = mStack->GetCurrentLayer();
	CMacPartBase*	currMacPart = NULL;
	size_t			numParts = owner->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*		currPart = owner->GetPart( x );
		currMacPart = dynamic_cast<CMacPartBase*>(currPart);
		if( currMacPart && currPart->IsSelected() )
		{
			NSMutableDictionary*	oldAttrs = [currMacPart->GetCocoaAttributesForPart() mutableCopy];
			NSFont*					theFont = [oldAttrs objectForKey: NSFontAttributeName];
			if( theFont )
			{
				[oldAttrs setObject: [sender convertFont: theFont] forKey: NSFontAttributeName];
				currMacPart->SetCocoaAttributesForPart( oldAttrs );
			}
			[oldAttrs release];
		}
	}
}


-(void)	changeAttributes: (NSFontManager*)sender
{
	CAutoreleasePool	pool;
	CLayer		*	owner = mStack->GetCurrentLayer();
	CMacPartBase*	currMacPart = NULL;
	size_t			numParts = owner->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*		currPart = owner->GetPart( x );
		currMacPart = dynamic_cast<CMacPartBase*>(currPart);
		if( currMacPart && currPart->IsSelected() )
		{
			NSDictionary*	oldAttrs = currMacPart->GetCocoaAttributesForPart();
			currMacPart->SetCocoaAttributesForPart( [sender convertAttributes: oldAttrs] );
		}
	}
}


-(void)	reflectFontOfSelectedParts
{
	CAutoreleasePool	pool;
	CLayer		*		owner = mStack->GetCurrentCard()->GetBackground();
	CMacPartBase*		currMacPart = NULL;
	size_t				numParts = owner->GetNumParts();
	BOOL				multiple = NO;
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*		currPart = owner->GetPart( x );
		currMacPart = dynamic_cast<CMacPartBase*>(currPart);
		if( currMacPart && currPart->IsSelected() )
		{
			NSDictionary*	attrs = currMacPart->GetCocoaAttributesForPart();
			NSFont*			theFont = [attrs objectForKey: NSFontAttributeName];
			if( theFont )
			{
				[[NSFontManager sharedFontManager] setSelectedFont: theFont isMultiple: multiple];
				multiple = YES;
			}
			[[NSFontManager sharedFontManager] setSelectedAttributes: attrs isMultiple: multiple];
		}
	}

	if( !mStack->GetEditingBackground() )
	{
		owner = mStack->GetCurrentCard();
		numParts = owner->GetNumParts();
		for( size_t x = 0; x < numParts; x++ )
		{
			CPart*		currPart = owner->GetPart( x );
			currMacPart = dynamic_cast<CMacPartBase*>(currPart);
			if( currMacPart && currPart->IsSelected() )
			{
				NSDictionary*	attrs = currMacPart->GetCocoaAttributesForPart();
				NSFont*			theFont = [attrs objectForKey: NSFontAttributeName];
				if( theFont )
				{
					[[NSFontManager sharedFontManager] setSelectedFont: theFont isMultiple: multiple];
					multiple = YES;
				}
				[[NSFontManager sharedFontManager] setSelectedAttributes: attrs isMultiple: multiple];
			}
		}
	}
}

@end
