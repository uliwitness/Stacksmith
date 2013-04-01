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


void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOPushMeInstruction( LEOContext* inContext );


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
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		LEOValuePtr	theValue = LEOGetValueForKey( theObject, propNameStr, thePropertyName, kLEOInvalidateReferences, inContext );
		if( !theValue )
		{
			LEOContextStopWithError( inContext, "Can't get property \"%s\" of this.", propNameStr );
			return;
		}
		else if( theValue != thePropertyName )
			LEOInitCopy( theValue, thePropertyName, kLEOInvalidateReferences, inContext );
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
		id<WILDObject>	theObjCObject = (id<WILDObject>)theObjectValue->object.object;
		NSString	*	propNameObjCStr = [NSString stringWithUTF8String: propNameStr];
		id				theObjCValue = WILDObjCObjectFromLEOValue( theValue, inContext, [theObjCObject typeForWILDPropertyNamed: propNameObjCStr] );
		
		@try
		{
			if( ![theObjCObject setValue: theObjCValue forWILDPropertyNamed: propNameObjCStr inRange: NSMakeRange(0,0)] )
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


LEOINSTR_START(Property,LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOPushPropertyOfObjectInstruction)
LEOINSTR(LEOSetPropertyOfObjectInstruction)
LEOINSTR_LAST(LEOPushMeInstruction)


