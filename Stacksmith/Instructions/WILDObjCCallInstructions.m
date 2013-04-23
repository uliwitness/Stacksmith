//
//  ForgeHostFunctionsStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "LEOObjCCallInstructions.h"
#include "ForgeWILDObjectValue.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDLayer.h"
#import "WILDCard.h"
#import "WILDPart.h"
#import "LEOScript.h"


void	WILDObjCCallInstruction( LEOContext* inContext );


void	WILDObjCCallInstruction( LEOContext* inContext )
{
	//LEODebugPrintContext(inContext);
	
	int				paramCount = inContext->currentInstruction->param1;
	LEOValuePtr		frameworkName = inContext->stackEndPtr -1 -paramCount;
	LEOValuePtr		signatureStr = inContext->stackEndPtr -2 -paramCount;
	LEOValuePtr		methodNameStr = inContext->stackEndPtr -3 -paramCount;
	LEOValuePtr		receiver = inContext->stackEndPtr -4 -paramCount;
	
	char			frameworkStrBuf[256] = {};
	const char*		frameworkStr = LEOGetValueAsString( frameworkName, frameworkStrBuf, sizeof(frameworkStrBuf), inContext );
	char			typesStrBuf[256] = {};
	const char*		typesStr = LEOGetValueAsString( signatureStr, typesStrBuf, sizeof(typesStrBuf), inContext );
	char			selNameBuf[256] = {};
	const char*		selName = LEOGetValueAsString( methodNameStr, selNameBuf, sizeof(selNameBuf), inContext );
	SEL				methodSelector = NSSelectorFromString( [NSString stringWithUTF8String: selName] );
	
	// Ensure the framework is loaded:
	NSString			*	fmwkNameObjC = [NSString stringWithUTF8String: frameworkStr];
	NSString			*	fmwkPath = [NSString stringWithFormat: @"/System/Library/Frameworks/%@.framework", fmwkNameObjC];
	NSBundle			*	theBundle = [NSBundle bundleWithPath: fmwkPath];
	if( theBundle && ![theBundle isLoaded] )
	{
		[theBundle load];
		UKLog( @"Loaded \"%@\" framework at \"%@\" is %p", fmwkNameObjC, fmwkPath, theBundle );
	}
	// Now get the class/object to send to:
	id				theReceiver = nil;
	
	if( receiver->base.isa == &kLeoValueTypeString )
		theReceiver = NSClassFromString( [NSString stringWithUTF8String: receiver->string.string] );
	else if( receiver->base.isa == &kLeoValueTypeNativeObject )
		theReceiver = (id)receiver->object.object;
	else
	{
		LEOContextStopWithError( inContext, "Invalid receiver of method call \"%s\".", methodNameStr );
		return;
	}
	
	if( !theReceiver )	// Short-circuit name
	{
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -paramCount -4 );
		LEOValuePtr	retValValue = LEOPushValueOnStack( inContext, NULL );
		LEOInitNativeObjectValue( retValValue, nil, kLEOInvalidateReferences, inContext );	// +++ Should be a special 'native object' type that doesn't convert to any usable type.
		inContext->currentInstruction++;
		return;
	}
	
	NSArray				*	typesArray = [[NSString stringWithUTF8String: typesStr] componentsSeparatedByString: @","];
	NSMethodSignature	*	theSignature = [theReceiver methodSignatureForSelector: methodSelector];
	if( !theSignature )
	{
		LEOContextStopWithError( inContext, "Can't determine signature for method call \"%s\".", selName );
		return;
	}
	NSInvocation		*	inv = [NSInvocation invocationWithMethodSignature: theSignature];
	[inv setTarget: theReceiver];
	[inv setSelector: methodSelector];
	
	for( int x = 0; x < paramCount; x++ )
	{
		NSString	*	currType = [typesArray objectAtIndex: x +1];
		LEOValuePtr		currParam = inContext->stackEndPtr -x;
		if( [currType isEqualToString: @"NSString*"] )
		{
			char			currParamStrBuf[256] = {};
			const char*		currParamStr = LEOGetValueAsString( currParam, currParamStrBuf, sizeof(currParamStrBuf), inContext );
			
			NSString	*	objCStr = [NSString stringWithUTF8String: currParamStr];
			[inv setArgument: &objCStr atIndex: x];
		}
		else if( [currType isEqualToString: @"int"] )
		{
			int				cNum = (int) LEOGetValueAsInteger( currParam, inContext );
			[inv setArgument: &cNum atIndex: x];
		}
		else if( [currType isEqualToString: @"long"] )
		{
			long			cNum = LEOGetValueAsInteger( currParam, inContext );
			[inv setArgument: &cNum atIndex: x];
		}
		else if( [currType isEqualToString: @"long long"] )
		{
			long long		cNum = LEOGetValueAsInteger( currParam, inContext );
			[inv setArgument: &cNum atIndex: x];
		}
		else if( [currType hasSuffix: @"*"] )
		{
			if( receiver->base.isa != &kLeoValueTypeNativeObject )
			{
				LEOContextStopWithError( inContext, "Invalid parameter %d to method call \"%s\".", x +1, methodNameStr );
				return;
			}

			id	obj = (id) currParam->object.object;
			[inv setArgument: &obj atIndex: x];
		}
		else
		{
			LEOContextStopWithError( inContext, "Unknown type of parameter %d to method call \"%s\".", x +1, methodNameStr );
			return;
		}
	}
	
	[inv invoke];
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -paramCount -4 );
	
	NSString	*	returnType = typesArray[0];
	if( [returnType isEqualToString: @"NSString*"] )
	{
		NSString	*	retVal = nil;
		[inv getReturnValue: &retVal];
		const char*	retStr = [retVal UTF8String];
		LEOPushStringValueOnStack( inContext, retStr, strlen(retStr) );
	}
	else if( [returnType isEqualToString: @"int"] )
	{
		int	retVal = 0;
		[inv getReturnValue: &retVal];
		LEOPushIntegerOnStack( inContext, retVal );
	}
	else if( [returnType isEqualToString: @"long"] )
	{
		long	retVal = 0;
		[inv getReturnValue: &retVal];
		LEOPushIntegerOnStack( inContext, retVal );
	}
	else if( [returnType isEqualToString: @"long long"] )
	{
		long long	retVal = 0;
		[inv getReturnValue: &retVal];
		LEOPushIntegerOnStack( inContext, retVal );
	}
	else if( [returnType hasSuffix: @"*"] )
	{
		void	*	retVal = NULL;
		[inv getReturnValue: &retVal];
		LEOValuePtr	retValValue = LEOPushValueOnStack( inContext, NULL );
		LEOInitNativeObjectValue( retValValue, retVal, kLEOInvalidateReferences, inContext );
	}
	else
	{
		LEOContextStopWithError( inContext, "Unknown type of return value from method call \"%s\".", methodNameStr );
		return;
	}
	
	//LEODebugPrintContext(inContext);
	
	inContext->currentInstruction++;
}


LEOINSTR_START(ObjCCall,LEO_NUMBER_OF_OBJCCALL_INSTRUCTIONS)
LEOINSTR_LAST(WILDObjCCallInstruction)


