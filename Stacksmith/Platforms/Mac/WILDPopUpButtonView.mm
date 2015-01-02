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
	self->owningPart = NULL;

	[super dealloc];
}


-(void)	setOwningPart: (CButtonPart*)inPart
{
	self->owningPart = inPart;
}


-(void)	mouseDown: (NSEvent*)event
{
	if( !self.isEnabled )
		return;
	
	lastButtonNumber = [event buttonNumber] +1;
	lastMouseUpWasInside = false;
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseDown %ld", lastButtonNumber );
	}
	
	[super mouseDown: event];
	
	if( !lastMouseUpWasInside )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUpOutside %ld", lastButtonNumber );
	}
}


-(BOOL)	sendAction: (SEL)theAction to: (id)theTarget
{
	lastMouseUpWasInside = true;
	self->owningPart->PrepareMouseUp();
	CAutoreleasePool	cppPool;
	self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUp %ld", lastButtonNumber );
	self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
	
	return [super sendAction: theAction to: theTarget];
}


-(void)	resetCursorRects
{
	NSCursor	*	currentCursor = nil;
	if( !currentCursor )
	{
		int			hotSpotLeft = 0, hotSpotTop = 0;
		std::string	cursorURL = self->owningPart->GetDocument()->GetMediaCache().GetMediaURLByIDOfType( 128, EMediaTypeCursor, &hotSpotLeft, &hotSpotTop );
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
