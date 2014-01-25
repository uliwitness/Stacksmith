//
//  WILDPopUpButtonView.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-25.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDPopUpButtonView.h"
#import "UKHelperMacros.h"
#include "CButtonPart.h"
#include "CAlert.h"
#include "CDocument.h"


using namespace Carlson;


@implementation WILDPopUpButtonView

@synthesize owningPart = owningPart;

-(void)	dealloc
{
	if( self->owningPart )
		self->owningPart->Release();

	[super dealloc];
}


-(void)	setOwningPart: (CButtonPart*)inPart
{
	if( self->owningPart != inPart )
	{
		if( self->owningPart )
			self->owningPart->Release();
		if( inPart )
			self->owningPart = (CButtonPart*) inPart->Retain();
		else
			self->owningPart = NULL;
	}
}


-(void)	mouseDown: (NSEvent*)event
{
	if( !self.isEnabled )
		return;
	
	lastButtonNumber = [event buttonNumber] +1;
	lastMouseUpWasInside = false;
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char* errMsg,size_t,size_t,CScriptableObject*) { if( errMsg ) CAlert::RunMessageAlert(errMsg); }, "mouseDown %ld", lastButtonNumber );
	}
	
	[super mouseDown: event];
	
	if( !lastMouseUpWasInside )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char* errMsg,size_t,size_t,CScriptableObject*) { if( errMsg ) CAlert::RunMessageAlert(errMsg); }, "mouseUpOutside %ld", lastButtonNumber );
	}
}


-(BOOL)	sendAction: (SEL)theAction to: (id)theTarget
{
	lastMouseUpWasInside = true;
	self->owningPart->PrepareMouseUp();
	CAutoreleasePool	cppPool;
	self->owningPart->SendMessage( NULL, [](const char* errMsg,size_t,size_t,CScriptableObject*) { if( errMsg ) CAlert::RunMessageAlert(errMsg); }, "mouseUp %ld", lastButtonNumber );
	
	return [super sendAction: theAction to: theTarget];
}


-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = nil;
	if( !currentCursor )
	{
		int			hotSpotLeft = 0, hotSpotTop = 0;
		std::string	cursorURL = self->owningPart->GetDocument()->GetMediaURLByIDOfType( 128, EMediaTypeCursor, &hotSpotLeft, &hotSpotTop );
		if( cursorURL.length() > 0 )
		{
			NSImage	*			cursorImage = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cursorURL.c_str()]]] autorelease];
			NSCursor *			cursorInstance = [[NSCursor alloc] initWithImage: cursorImage hotSpot: NSMakePoint(hotSpotLeft,hotSpotTop)];
			currentCursor = cursorInstance;
		}
	}
	if( !currentCursor )
		currentCursor = [NSCursor arrowCursor];
	[self addCursorRect: [self bounds] cursor: currentCursor];
}

@end
