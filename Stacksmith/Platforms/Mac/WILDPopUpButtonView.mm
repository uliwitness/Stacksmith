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
	DESTROY_DEALLOC(mCursor);

	[super dealloc];
}


-(void)	setOwningPart: (CButtonPart*)inPart
{
	self->owningPart = inPart;
	[self reloadCursor];
}


-(void)	reloadCursor
{
	ASSIGN( mCursor, [NSCursor arrowCursor] );
	self->owningPart->GetDocument()->GetMediaCache().GetMediaImageByIDOfType( self->owningPart->GetCursorID(), EMediaTypeCursor, [self]( WILDNSImagePtr theImage, int xHotSpot, int yHotSpot )
	{
		DESTROY(mCursor);
		mCursor = [[NSCursor alloc] initWithImage: theImage hotSpot: NSMakePoint(xHotSpot,yHotSpot)];
	} );
}


-(void)	mouseDown: (NSEvent*)event
{
	if( !self.isEnabled )
		return;
	
	lastButtonNumber = [event buttonNumber] +1;
	lastMouseUpWasInside = false;
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseDown %ld", lastButtonNumber );
	}
	
	[super mouseDown: event];
	
	if( !lastMouseUpWasInside )
	{
		CAutoreleasePool	cppPool;
		self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUpOutside %ld", lastButtonNumber );
	}
}


-(BOOL)	sendAction: (SEL)theAction to: (id)theTarget
{
	lastMouseUpWasInside = true;
	self->owningPart->PrepareMouseUp();
	CAutoreleasePool	cppPool;
	self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "mouseUp %ld", lastButtonNumber );
	self->owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "selectionChange" );
	
	return [super sendAction: theAction to: theTarget];
}


-(void)	resetCursorRects
{
	[self addCursorRect: [self bounds] cursor: (self.owningPart->GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : mCursor];
}

@end
