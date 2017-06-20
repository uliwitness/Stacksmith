//
//  CAlert.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CAlert.h"
#include "CScriptableObjectValue.h"
#import "WILDIOSMainViewController.h"
#import <UIKit/UIKit.h>


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
	@try
	{
		NSString * messageText = [NSString stringWithCString: inMessage.c_str() encoding:NSUTF8StringEncoding];
		UIAlertController * theAlert = [UIAlertController alertControllerWithTitle: nil message: messageText preferredStyle: UIAlertControllerStyleActionSheet];
		if( button1.length() > 0 )
		{
			NSString * button1Title = [NSString stringWithCString: button1.c_str() encoding:NSUTF8StringEncoding];
			[theAlert addAction: [UIAlertAction actionWithTitle: button1Title style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action)
			{
				completionHandler(1);
			}]];
			if( button2.length() > 0 )
			{
				NSString * button2Title = [NSString stringWithCString: button2.c_str() encoding:NSUTF8StringEncoding];
				[theAlert addAction: [UIAlertAction actionWithTitle: button2Title style: UIAlertActionStyleCancel handler: ^(UIAlertAction *action)
									  {
										  completionHandler(2);
									  }]];
				if( button3.length() > 0 )
				{
					NSString * button3Title = [NSString stringWithCString: button3.c_str() encoding:NSUTF8StringEncoding];
					[theAlert addAction: [UIAlertAction actionWithTitle: button3Title style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action)
										  {
											  completionHandler(3);
										  }]];
				}
			}
		}
		
		[WILDIOSMainViewController.sharedMainViewController presentViewController: theAlert animated:YES completion:nil];
	}
	@catch( NSException * err )
	{
		NSLog(@"Unexpected exception during error dialog: %@", err);
	}
}


void	CAlert::RunInputAlert( const std::string& inMessage, const std::string& inInputText, std::function<void(bool,std::string)> completionHandler )
{
	@try
	{
		NSString * messageText = [NSString stringWithUTF8String: inMessage.c_str()];
		NSString * proposedAnswer = [NSString stringWithUTF8String: inInputText.c_str()];
		
		UIAlertController * theAlert = [UIAlertController alertControllerWithTitle: nil message: messageText preferredStyle: UIAlertControllerStyleActionSheet];
		[theAlert addAction: [UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action)
						  {
							  completionHandler(true,theAlert.textFields[0].text.UTF8String);
						  }]];
		[theAlert addAction: [UIAlertAction actionWithTitle: @"Cancel" style: UIAlertActionStyleCancel handler: ^(UIAlertAction *action)
						  {
							  completionHandler(false,theAlert.textFields[0].text.UTF8String);
						  }]];
		[theAlert addTextFieldWithConfigurationHandler: nil];
		theAlert.textFields[0].text = proposedAnswer;
		
		[WILDIOSMainViewController.sharedMainViewController presentViewController: theAlert animated:YES completion:nil];
	}
	@catch( NSException * err )
	{
		NSLog(@"Unexpected exception during error dialog: %@", err);
	}
}
