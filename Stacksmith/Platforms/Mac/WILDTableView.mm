//
//  WILDTableView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDTableView.h"
#include "CAlert.h"

using namespace Carlson;


@implementation WILDTableView

@synthesize owningPart = owningPart;

-(void)	mouseDown: (NSEvent*)evt
{
	if( [self.window isKeyWindow] && owningPart )	// When the window isn't active, the table ignores the front click and we'd send a mouseDown w/o a mouseUp.
	{
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, "mouseDown %ld", [evt buttonNumber] );
	}
	[super mouseDown: evt];
}


//-(void)	mouseUp: (NSEvent*)evt
//{
//	NSLog(@"mouseUp START");
//	[super mouseUp: evt];
//	NSLog(@"mouseUp END");
//}


-(BOOL)	becomeFirstResponder
{
	BOOL state = [super becomeFirstResponder];
	if( state && owningPart )
	{
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, "openField" );
	}
	return state;
}


-(BOOL)	resignFirstResponder
{
	BOOL state = [super resignFirstResponder];
	if( state && owningPart )
	{
		CAutoreleasePool		pool;
		owningPart->SendMessage( NULL, [](const char *errMsg, size_t inLineOffset, size_t inOffset, CScriptableObject* inErrObj, bool wasHandled){ CAlert::RunScriptErrorAlert( inErrObj, errMsg, inLineOffset, inOffset ); }, EMayGoUnhandled, "closeField" );
	}
	return state;
}

@end
