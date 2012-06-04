/*
 *  ForgePropertyInstructionsStacksmith.c
 *  Leonie
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

#import "Forge.h"
#import "ForgeWILDObjectValue.h"
#import "ForgeObjCConversion.h"


void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -2;
	LEOValuePtr		theObject = inContext->stackEndPtr -1;
	
	char			propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr		objectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeWILDObject, inContext );
	if( objectValue )
	{
		id propValueObj = [(id<WILDObject>)objectValue->object.object valueForWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr] ofRange: NSMakeRange(0,0)];
		if( !propValueObj )
		{
			LEOContextStopWithError( inContext,"Object does not have property \"%s\".", propNameStr );
			return;
		}
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		
		if( !WILDObjCObjectToLEOValue( propValueObj, thePropertyName, inContext ) )
		{
			LEOContextStopWithError( inContext, "Internal Error: property '%s' returned unknown value.", propNameStr );
			return;
		}
	}
	else
	{
		LEOValuePtr	theValue = LEOGetValueForKey( theObject, propNameStr, inContext );
		if( theValue )
		{
			LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
			LEOInitCopy( theValue, thePropertyName, kLEOInvalidateReferences, inContext );
		}
		else
		{
			LEOContextStopWithError( inContext, "Can't get property \"%s\" of this.", propNameStr );
			return;
		}
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		theValue = inContext->stackEndPtr -1;
	LEOValuePtr		theObject = inContext->stackEndPtr -2;
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -3;
	
	char		propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr	theObjectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeWILDObject, inContext );
	
	if( theObjectValue )
	{
		id			theObjCValue = WILDObjCObjectFromLEOValue( theValue, inContext );
		
		@try
		{
			if( ![(id<WILDObject>)theObjectValue->object.object setValue: theObjCValue forWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr] inRange: NSMakeRange(0,0)] )
			{
				LEOContextStopWithError( inContext, "Object does not have property \"%s\".", propNameStr );
				return;
			}
		}
		@catch( NSException* exc )
		{
			LEOContextStopWithError( inContext, "Error retrieving property \"%s\": %s", propNameStr, [[exc reason] UTF8String] );
			return;
		}
	}
	else
	{
		LEOSetValueForKey( theObject, propNameStr, theValue, inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -3 );
	
	inContext->currentInstruction++;
}


void	LEOPushMeInstruction( LEOContext* inContext )
{
	LEOScript	*	myScript = LEOContextPeekCurrentScript( inContext );
	
	inContext->stackEndPtr++;
	
	LEOInitReferenceValueWithIDs( inContext->stackEndPtr -1, myScript->ownerObject, myScript->ownerObjectSeed,
									  kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr	gPropertyInstructions[LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS] =
{
	LEOPushPropertyOfObjectInstruction,
	LEOSetPropertyOfObjectInstruction,
	LEOPushMeInstruction
};


const char*		gPropertyInstructionNames[LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS] =
{
	"PushPropertyOfObject",
	"SetPropertyOfObject",
	"PushMe"
};
