//
//  CAlert.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAlert.h"
#import "WILDInputPanelController.h"
#import <AppKit/AppKit.h>
#include "CScriptableObjectValue.h"


using namespace Carlson;


void	CAlert::RunScriptErrorAlert( CScriptableObject* inErrObj, const char* errMsg, size_t inLineOffset, size_t inOffset )
{
	if( !errMsg || !inErrObj )
		return;
	
	if( 2 == RunMessageAlert( errMsg, "Abort", (inLineOffset != SIZE_T_MAX) ? "Edit Script" : std::string() ) )
	{
		if( inOffset != SIZE_T_MAX )
			inErrObj->OpenScriptEditorAndShowOffset( inOffset );
		else
			inErrObj->OpenScriptEditorAndShowLine( inLineOffset );
	}
}


size_t	CAlert::RunMessageAlert( const std::string& inMessage, const std::string& button1, const std::string& button2, const std::string& button3 )
{
	NSInteger	returnValue = 0;
	@try
	{
		returnValue = NSRunAlertPanel( [NSString stringWithCString: inMessage.c_str() encoding:NSUTF8StringEncoding], @"", [NSString stringWithCString: button1.c_str() encoding:NSUTF8StringEncoding], [NSString stringWithCString: button2.c_str() encoding:NSUTF8StringEncoding], [NSString stringWithCString: button3.c_str() encoding:NSUTF8StringEncoding] );
	}
	@catch( NSException * err )
	{
		
	}
	
	switch( returnValue )
	{
		case NSAlertDefaultReturn:
			return 1;
		case NSAlertAlternateReturn:
			return 2;
		case NSAlertOtherReturn:
			return 3;
		default:
			return 0;
	}
}


bool	CAlert::RunInputAlert( const std::string& inMessage, std::string& ioInputText )
{
	WILDInputPanelController	*	inputPanel = [WILDInputPanelController inputPanelWithPrompt: [NSString stringWithUTF8String: inMessage.c_str()] answer: [NSString stringWithUTF8String: ioInputText.c_str()]];
	NSInteger		returnValue = [inputPanel runModal];
	NSString	*	answerString = [inputPanel answerString];
	ioInputText = [answerString UTF8String];

	return returnValue == NSAlertDefaultReturn;
}
