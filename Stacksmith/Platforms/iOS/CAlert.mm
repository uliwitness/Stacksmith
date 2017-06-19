//
//  CAlert.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAlert.h"
#import <UIKit/UIKit.h>
#include "CScriptableObjectValue.h"


using namespace Carlson;


void	CAlert::RunScriptErrorAlert( CScriptableObject* inErrObj, const char* errMsg, size_t inLineOffset, size_t inOffset )
{
	if( !errMsg || !inErrObj )
		return;
	
	inErrObj->Retain();
	RunMessageAlert( errMsg, "Abort", (inLineOffset != SIZE_T_MAX) ? "Edit Script" : std::string(), std::string(), [inErrObj,inOffset,inLineOffset]( size_t buttonClicked )
	{
		if( 2 == buttonClicked )
		{
			if( inOffset != SIZE_T_MAX )
				inErrObj->OpenScriptEditorAndShowOffset( inOffset );
			else
				inErrObj->OpenScriptEditorAndShowLine( inLineOffset );
		}
		inErrObj->Release();
	} );
}


void	CAlert::RunMessageAlert( const std::string& inMessage, const std::string& button1, const std::string& button2, const std::string& button3, std::function<void(size_t)> completionHandler )
{
	NSInteger	returnValue = 0;
	@try
	{
		NSAlert	*	theAlert = [[NSAlert new] autorelease];
		theAlert.messageText = [NSString stringWithCString: inMessage.c_str() encoding:NSUTF8StringEncoding];
		if( button1.length() > 0 )
		{
			[theAlert addButtonWithTitle: [NSString stringWithCString: button1.c_str() encoding:NSUTF8StringEncoding]];
			if( button2.length() > 0 )
			{
				[theAlert addButtonWithTitle: [NSString stringWithCString: button2.c_str() encoding:NSUTF8StringEncoding]];
				if( button3.length() > 0 )
				{
					[theAlert addButtonWithTitle: [NSString stringWithCString: button3.c_str() encoding:NSUTF8StringEncoding]];
				}
			}
		}
		
		returnValue = [theAlert runModal];
	}
	@catch( NSException * err )
	{
		NSLog(@"Unexpected exception during error dialog: %@", err);
	}
	
	switch( returnValue )
	{
		case NSAlertFirstButtonReturn:
			completionHandler(1);
			break;
		case NSAlertSecondButtonReturn:
			completionHandler(2);
			break;
		case NSAlertThirdButtonReturn:
			completionHandler(3);
			break;
		default:
			completionHandler(0);
	}
}


void	CAlert::RunInputAlert( const std::string& inMessage, const std::string& inInputText, std::function<void(bool,std::string)> completionHandler )
{
	ULIInputPanelController	*	inputPanel = [ULIInputPanelController inputPanelWithPrompt: [NSString stringWithUTF8String: inMessage.c_str()] answer: [NSString stringWithUTF8String: inInputText.c_str()]];
	NSInteger		returnValue = [inputPanel runModal];
	NSString	*	answerString = [inputPanel answerString];

	completionHandler( returnValue == NSAlertFirstButtonReturn, [answerString UTF8String] );
}
