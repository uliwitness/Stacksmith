//
//  WILDObjCCallInstructions.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*!
	@header WILDObjCCallInstructions
	While Forge knows how to parse inline Objective-C expressions, they might
	not make sense on every platform, and how to call them may differ between
	platforms, so is implemented in this separate file.
	
	It is OK to replace this code with an instruction that just displays an error,
	if it makes more sense on your platform. However, it is desirable to still parse
	the code correctly and wait until runtime to fail, so scripts can contain
	Mac-specific code but avoid the error by examining the 'platform' property.
*/

#include "LEOObjCCallInstructions.h"
#include "WILDObjectValue.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDLayer.h"
#import "WILDCard.h"
#import "WILDPart.h"
#import "LEOScript.h"


void	WILDObjCCallInstruction( LEOContext* inContext );


/*!
	Call an ObjC method on an object or class. The instruction's parameters are:
	
	param1	-	The number of parameters the method takes.
	param2	-	unused.
	
	Also, this instruction requires at least 4 parameters on the stack,
	more if the method itself takes parameters, which are pushed after the first
	required four. On completion, all parameters are popped off the stack and
	the result of the method call is pushed on the stack instead. If the method
	returns void, an empty string is pushed.
	
	receiver	-	The object to send the message to. This must be a value of
					type 'native object' or a string. If it is the latter, the
					string will be taken to be the name of a class to send the
					message to.
	methodName -	The name of the message to send (the selector as a string,
					if you will). E.g. doThis:withThat: or just doSomething if
					it takes no parameters.
	signature -		The types of the parameters this method requires, as a comma-
					delimited string. The first item in this list is the return
					type of this method.
	frameworkName -	The name of the framework (i.e. library) that defines the
					class and method you are calling. If it hasn't been loaded
					yet, this instruction will load the framework from
					/System/Library/Frameworks/ to make sure it is available.
	
	As far as possible, this method will attempt to convert between LEOValues and
	the corresponding native types. Where that fails, it will wrap any pointers
	in 'Native Object' values, which can't be written to disk or stored in globals,
	fields or user properties, and it will present an error for the rest.
	
	(CALL_OBJC_METHOD_INSTR)
*/

void	WILDObjCCallInstruction( LEOContext* inContext )
{
	@try
	{
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
			else if( [currType isEqualToString: @"const char*"] )
			{
				char			currParamStrBuf[256] = {};
				const char*		currParamStr = LEOGetValueAsString( currParam, currParamStrBuf, sizeof(currParamStrBuf), inContext );
				
				[inv setArgument: &currParamStr atIndex: x];
			}
			else if( [currType isEqualToString: @"char"] )
			{
				char			currParamStrBuf[256] = {};
				const char*		currParamStr = LEOGetValueAsString( currParam, currParamStrBuf, sizeof(currParamStrBuf), inContext );
				
				[inv setArgument: (void*) currParamStr atIndex: x];
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
			else if( [currType isEqualToString: @"double"] )
			{
				double			cNum = LEOGetValueAsNumber( currParam, inContext );
				[inv setArgument: &cNum atIndex: x];
			}
			else if( [currType isEqualToString: @"float"] )
			{
				float			cNum = LEOGetValueAsNumber( currParam, inContext );
				[inv setArgument: &cNum atIndex: x];
			}
			else if( [currType isEqualToString: @"bool"] )
			{
				bool			cFlag = LEOGetValueAsBoolean( currParam, inContext );
				[inv setArgument: &cFlag atIndex: x];
			}
			else if( [currType isEqualToString: @"BOOL"] )
			{
				BOOL			cFlag = LEOGetValueAsBoolean( currParam, inContext );
				[inv setArgument: &cFlag atIndex: x];
			}
			else if( [currType isEqualToString: @"Boolean"] )
			{
				Boolean			cFlag = LEOGetValueAsBoolean( currParam, inContext );
				[inv setArgument: &cFlag atIndex: x];
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
				LEOContextStopWithError( inContext, "Unknown type \"%s\" of parameter %d to method call \"%s\".", [currType UTF8String], x +1, methodNameStr );
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
		else if( [returnType isEqualToString: @"const char*"] )
		{
			const char*	retStr = NULL;
			[inv getReturnValue: &retStr];
			LEOPushStringValueOnStack( inContext, retStr, strlen(retStr) );
		}
		else if( [returnType isEqualToString: @"char"] )
		{
			char	retStr[2] = {};
			[inv getReturnValue: retStr];
			
			LEOPushStringValueOnStack( inContext, retStr, 1 );
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
		else if( [returnType isEqualToString: @"double"] )
		{
			double	retVal = 0;
			[inv getReturnValue: &retVal];
			LEOPushNumberOnStack( inContext, retVal );
		}
		else if( [returnType isEqualToString: @"float"] )
		{
			float	retVal = 0;
			[inv getReturnValue: &retVal];
			LEOPushNumberOnStack( inContext, retVal );
		}
		else if( [returnType isEqualToString: @"bool"] )
		{
			bool	retVal = 0;
			[inv getReturnValue: &retVal];
			LEOPushBooleanOnStack( inContext, retVal );
		}
		else if( [returnType isEqualToString: @"BOOL"] )
		{
			BOOL	retVal = 0;
			[inv getReturnValue: &retVal];
			LEOPushBooleanOnStack( inContext, retVal );
		}
		else if( [returnType isEqualToString: @"Boolean"] )
		{
			Boolean	retVal = 0;
			[inv getReturnValue: &retVal];
			LEOPushBooleanOnStack( inContext, retVal );
		}
		else if( [returnType hasSuffix: @"*"] )
		{
			void	*	retVal = NULL;
			[inv getReturnValue: &retVal];
			LEOValuePtr	retValValue = LEOPushValueOnStack( inContext, NULL );
			LEOInitNativeObjectValue( retValValue, retVal, kLEOInvalidateReferences, inContext );
		}
		else if( [returnType isEqualToString: @"void"] )
		{
			LEOPushEmptyValueOnStack( inContext );
		}
		else
		{
			LEOContextStopWithError( inContext, "Unknown return value of type \"%s\" from native method call \"%s\".", [returnType UTF8String], methodNameStr );
			return;
		}

	}
	@catch ( NSException* err )
	{
		LEOContextStopWithError( inContext, "Exception raised during method call: \"%s\".", [[err description] UTF8String] );
		return;
	}
	
	inContext->currentInstruction++;
}


LEOINSTR_START(ObjCCall,LEO_NUMBER_OF_OBJCCALL_INSTRUCTIONS)
LEOINSTR_LAST(WILDObjCCallInstruction)


