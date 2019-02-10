//
//  WILDButtonView.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import "WILDButtonView.h"
#import "UKHelperMacros.h"
#include "CDocument.h"
#include "CAlert.h"


using namespace Carlson;


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


@implementation WILDButtonView

@synthesize owningPart = owningPart;

-(void)	dealloc
{
	[self removeTrackingArea: mCursorTrackingArea];
	DESTROY_DEALLOC(mCursorTrackingArea);
	self->owningPart = NULL;
	DESTROY_DEALLOC(mCursor);

	[super dealloc];
}


-(void)	setOwningPart: (CButtonPart*)inPart
{
	self->owningPart = inPart;
	self.action = @selector(buttonTriggered:);
	self.target = self;
	[self reloadCursor];
}


-(void)	reloadCursor
{
	ASSIGN( mCursor, [NSCursor arrowCursor] );
	self->owningPart->GetDocument()->GetMediaCache().GetMediaImageByIDOfType( self->owningPart->GetCursorID(), EMediaTypeCursor, [self]( const CImageCanvas& inImageCanvas, int xHotSpot, int yHotSpot )
	{
		DESTROY(mCursor);
		NSImage * theImage = [[[NSImage alloc] initWithCGImage: inImageCanvas.GetMacImage() size: NSZeroSize] autorelease];
		mCursor = [[NSCursor alloc] initWithImage: theImage hotSpot: NSMakePoint(xHotSpot,yHotSpot)];
	} );
}


-(void)	mouseEntered:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseEnter %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseExited:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseLeave %ld", [theEvent buttonNumber] +1 );
	}
}


-(void)	mouseMoved:(NSEvent *)theEvent
{
	if( self->owningPart->GetShouldSendMouseEventsRightNow() )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseMove" );
	}
}


- (void)textDidEndEditing:(NSNotification *)notification
{
	[self setTitle: self.currentEditor.string];
	self->owningPart->SetName( self.currentEditor.string.UTF8String );
	[[self cell] endEditing: self.currentEditor];
}


-(void)	mouseDown: (NSEvent*)event
{
	if( self->owningPart->GetStack()->GetTool() == EEditTextTool )
	{
		NSRect		box = [[self cell] titleRectForBounds: self.bounds];
		if( NSPointInRect( [self convertPoint: [event locationInWindow] fromView: nil], box ) )
		{
			NSTextView*	fe = (NSTextView*) [self.window fieldEditor: YES forObject: self];
			[[self cell] editWithFrame: box inView: self editor: fe delegate: self event: event];
//			if( [fe respondsToSelector: @selector(setDrawsBackground:)] )
//				[fe setDrawsBackground: NO];
		}
		else if( self.currentEditor )
		{
			[[self cell] endEditing: self.currentEditor];
			[self.window makeFirstResponder: nil];
		}
		else
			[self.window makeFirstResponder: nil];
		return;
	}
	
	const char *        firstModifier = nil;
	const char *        secondModifier = nil;
	const char *        thirdModifier = nil;
	const char *        fourthModifier = nil;
	
	if( event.modifierFlags & NSEventModifierFlagShift )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shift" );
	else if( event.modifierFlags & NSEventModifierFlagCapsLock )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shiftlock" );
	if( event.modifierFlags & NSEventModifierFlagOption )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "alternate" );
	if( event.modifierFlags & NSEventModifierFlagControl )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "control" );
	if( event.modifierFlags & NSEventModifierFlagCommand )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "command" );
	
	if( !firstModifier ) firstModifier = "";
	if( !secondModifier ) secondModifier = "";
	if( !thirdModifier ) thirdModifier = "";
	if( !fourthModifier ) fourthModifier = "";

	BOOL					keepLooping = YES;
	BOOL					autoHighlight = self->owningPart->GetAutoHighlight();
	BOOL					isInside = [[self cell] hitTestForEvent: event inRect: [self bounds] ofView: self] != NSCellHitNone;
	BOOL					newIsInside = isInside;
	
	if( !isInside || !self.isEnabled )
		return;
	
	if( autoHighlight && isInside )
	{
		[[self cell] setHighlighted: YES];
		self->owningPart->SetHighlightForTracking(isInside);
	}
	
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseDown %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	
	NSAutoreleasePool	*	pool = [[NSAutoreleasePool alloc] init];
	
	while( keepLooping )
	{
		NSEvent	*	evt = [NSApp nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged | NSEventMaskOtherMouseDragged untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( evt )
		{
			switch( [evt type] )
			{
				 case NSEventTypeLeftMouseUp:
				 case NSEventTypeRightMouseUp:
				 case NSEventTypeOtherMouseUp:
					keepLooping = NO;
					break;
				
				case NSEventTypeLeftMouseDragged:
				case NSEventTypeRightMouseDragged:
				case NSEventTypeOtherMouseDragged:
				{
					newIsInside = [[self cell] hitTestForEvent: evt inRect: [self bounds] ofView: self] != NSCellHitNone;
					if( isInside != newIsInside )
					{
						isInside = newIsInside;

						if( autoHighlight )
						{
							[[self cell] setHighlighted: isInside];
							self->owningPart->SetHighlightForTracking(isInside);
						}
					}
					CAutoreleasePool	cppPool;
					self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseDrag %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
					break;
				}
				
				default:
					break;
			}
		}
		
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
	}
	
	if( isInside )
	{
		if( autoHighlight )
		{
			[[self cell] setHighlighted: NO];
			self->owningPart->SetHighlightForTracking(false);
			[self setNeedsDisplay: YES];
			[self.window display];
		}
		//[[self target] performSelector: [self action] withObject: self];
		self->owningPart->PrepareMouseUp();
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUp %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	else
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUpOutside %ld,%s,%s,%s,%s", [event buttonNumber] +1, firstModifier, secondModifier, thirdModifier, fourthModifier );
	}
	
	[pool release];
}


-(void)	resetCursorRects
{
	[super resetCursorRects];
	[self addCursorRect: [self bounds] cursor: (self.owningPart->GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : mCursor];
}


-(void)	updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mCursorTrackingArea )
	{
		[self removeTrackingArea: mCursorTrackingArea];
		DESTROY(mCursorTrackingArea);
	}
	NSTrackingAreaOptions	trackingOptions = 0;
	
	if( self.owningPart->HasOrInheritsMessageHandler("mouseEnter",nullptr) || self.owningPart->HasOrInheritsMessageHandler("mouseLeave",nullptr) )
		trackingOptions |= NSTrackingMouseEnteredAndExited;
	if( self.owningPart->HasOrInheritsMessageHandler("mouseMove",nullptr) )
		trackingOptions |= NSTrackingMouseMoved;
	
	if( trackingOptions != 0 )
	{
		trackingOptions |= NSTrackingActiveInActiveApp;
		mCursorTrackingArea = [[NSTrackingArea alloc] initWithRect: self.bounds options: trackingOptions owner: self userInfo: nil];
		[self addTrackingArea: mCursorTrackingArea];
	}
}


-(void)	windowDidChangeKeyOrMain: (NSNotification*)inNotif
{
	[self setNeedsDisplay: YES];
}


-(void)	viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	if( self.window )
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidBecomeKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidResignKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidBecomeMainNotification object: self.window];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidChangeKeyOrMain:) name: NSWindowDidResignMainNotification object: self.window];
	}
}


-(void)	viewWillMoveToWindow: (NSWindow *)newWindow
{
	if( self.window )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidBecomeKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignKeyNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidBecomeMainNotification object: self.window];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignMainNotification object: self.window];
	}
	
	[super viewWillMoveToWindow: newWindow];
}


-(IBAction)	buttonTriggered: (id)sender
{
	self->owningPart->PrepareMouseUp();
	CAutoreleasePool	cppPool;
	self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUp" );
}

@end
