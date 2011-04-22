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


void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -2;
	LEOValuePtr		theObject = inContext->stackEndPtr -1;
	
	char		propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	if( theObject->base.isa == &kLeoValueTypeWILDObject )
	{
		NSString*	str = [(id<WILDObject>)theObject->object.object valueForWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr]];
		if( !str )
		{
			snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Object does not have property \"%s\".", propNameStr );
			inContext->keepRunning = false;
			return;
		}
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		const char*	valueStr = [str UTF8String];
		LEOInitStringValue( thePropertyName, valueStr, strlen(valueStr), kLEOInvalidateReferences, inContext );
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
	
	char		theValueStrBuf[1024] = { 0 };
	char*		theValueStr = LEOGetValueAsString( theValue, theValueStrBuf, sizeof(theValueStrBuf), inContext );
	id			theObjCValue = [NSString stringWithUTF8String: theValueStr];
	
	if( theObject->base.isa == &kLeoValueTypeWILDObject )
	{
		if( ![(id<WILDObject>)theObject->object.object setValue: theObjCValue forWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr]] )
		{
			snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Object does not have property \"%s\".", propNameStr );
			inContext->keepRunning = false;
			return;
		}
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -3 );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr	gPropertyInstructions[LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS] =
{
	LEOPushPropertyOfObjectInstruction,
	LEOSetPropertyOfObjectInstruction
};


const char*		gPropertyInstructionNames[LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS] =
{
	"PushPropertyOfObject",
	"SetPropertyOfObject"
};
