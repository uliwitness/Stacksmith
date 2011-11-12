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
#import <Foundation/Foundation.h>

void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -2;
	LEOValuePtr		theObject = inContext->stackEndPtr -1;
	
	char			propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr		objectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeWILDObject, inContext );
	if( objectValue )
	{
		id propValueObj = [(id<WILDObject>)objectValue->object.object valueForWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr]];
		if( !propValueObj )
		{
			LEOContextStopWithError( inContext,"Object does not have property \"%s\".", propNameStr );
			return;
		}
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		if( propValueObj == kCFBooleanTrue || propValueObj == kCFBooleanFalse )
		{
			LEOInitBooleanValue( thePropertyName, (propValueObj == kCFBooleanTrue), kLEOInvalidateReferences, inContext );
		}
		else if( [propValueObj isKindOfClass: [NSString class]] )
		{
			const char*	valueStr = [propValueObj UTF8String];
			LEOInitStringValue( thePropertyName, valueStr, strlen(valueStr), kLEOInvalidateReferences, inContext );
		}
		else if( [propValueObj isKindOfClass: [NSNumber class]] )
		{
			if( strcmp([propValueObj objCType], @encode(long long)) == 0
				|| strcmp([propValueObj objCType], @encode(NSInteger)) == 0
				|| strcmp([propValueObj objCType], @encode(int)) == 0
				|| strcmp([propValueObj objCType], @encode(short)) == 0
				|| strcmp([propValueObj objCType], @encode(char)) == 0 )
			{
				LEOInitIntegerValue( thePropertyName, [propValueObj longLongValue], kLEOInvalidateReferences, inContext );
			}
			else
			{
				LEOInitNumberValue( thePropertyName, [propValueObj doubleValue], kLEOInvalidateReferences, inContext );
			}
		}
		else if( [propValueObj isKindOfClass: [NSDictionary class]] )
		{
			NSDictionary	*		theDict = propValueObj;
			struct LEOArrayEntry*	theArray = NULL;
			
			for( NSString* dictKey in theDict )
			{
				id				dictValue = [theDict objectForKey: dictKey];
				union LEOValue	dictValueCopy;
				if( [dictValue isKindOfClass: [NSString class]] )
				{
					const char*	valueStr = [dictValue UTF8String];
					LEOInitStringValue( &dictValueCopy, valueStr, strlen(valueStr), kLEOInvalidateReferences, inContext );
				}
				else if( [dictValue isKindOfClass: [NSNumber class]] )
				{
					LEOInitNumberValue( &dictValueCopy, [dictValue doubleValue], kLEOInvalidateReferences, inContext );
				}
				LEOAddArrayEntryToRoot( &theArray, [dictKey UTF8String], &dictValueCopy, inContext );
				
				LEOCleanUpValue( &dictValueCopy, kLEOInvalidateReferences, inContext );
			}
			LEOInitArrayValue( thePropertyName, theArray, kLEOInvalidateReferences, inContext );
		}
		else
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


void	AppendLEOArrayToDictionary( struct LEOArrayEntry * inEntry, NSMutableDictionary* dict, LEOContext *inContext )
{
	if( inEntry )
	{
		NSString	*	theKey = [NSString stringWithUTF8String: inEntry->key];
		char			strBuf[1024] = { 0 };
		NSString	*	theValue = [NSString stringWithUTF8String: LEOGetValueAsString( &inEntry->value, strBuf, sizeof(strBuf), inContext )];
		[dict setObject: theValue forKey: theKey];	// TODO: Don't always convert to string.
		
		if( inEntry->smallerItem )
			AppendLEOArrayToDictionary( inEntry->smallerItem, dict, inContext );
		if( inEntry->largerItem )
			AppendLEOArrayToDictionary( inEntry->largerItem, dict, inContext );
	}
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
		id			theObjCValue = nil;
		LEOValuePtr	theArrayValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeArray, inContext );
		if( !theArrayValue )
			theArrayValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeArrayVariant, inContext );
		if( theArrayValue )
		{
			theObjCValue = [NSMutableDictionary dictionary];
			AppendLEOArrayToDictionary( theArrayValue->array.array, theObjCValue, inContext );
		}
		else
		{
			char		theValueStrBuf[1024] = { 0 };
			char*		theValueStr = LEOGetValueAsString( theValue, theValueStrBuf, sizeof(theValueStrBuf), inContext );
			theObjCValue = [NSString stringWithUTF8String: theValueStr];
		}
		
		@try {
			if( ![(id<WILDObject>)theObjectValue->object.object setValue: theObjCValue forWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr]] )
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
