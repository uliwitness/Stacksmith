//
//  WILDObjectValue.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "WILDObjectValue.h"
#include "LEOInterpreter.h"
#include "LEOContextGroup.h"
#include "LEOScript.h"
#import "WILDObjCConversion.h"


NSString*	WILDUserPropertyNameKey = @"WILDUserPropertyNameKey";
NSString*	WILDUserPropertyValueKey = @"WILDUserPropertyValueKey";


LEONumber	WILDGetObjectValueAsNumber( LEOValuePtr self, LEOUnit* inUnit, struct LEOContext* inContext );

LEOInteger	WILDGetObjectValueAsInteger( LEOValuePtr self, LEOUnit* inUnit, struct LEOContext* inContext );

const char*	WILDGetObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, struct LEOContext* inContext );

bool		WILDGetObjectValueAsBoolean( LEOValuePtr self, struct LEOContext* inContext );

void		WILDGetObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, struct LEOContext* inContext );

void	WILDSetObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, LEOUnit inUnit, struct LEOContext* inContext );
void	WILDSetObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, LEOUnit inUnit, struct LEOContext* inContext );
void	WILDSetObjectValueAsString( LEOValuePtr self, const char* inBuf, size_t inBufLen, struct LEOContext* inContext );
void	WILDSetObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, struct LEOContext* inContext );
void	WILDSetObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext );
void	WILDSetObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext );
void	WILDInitObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );	// dest is an uninitialized value.
void	WILDInitObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );	// dest is an uninitialized value.
void	WILDPutObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, struct LEOContext* inContext );	// dest must be a VALID, initialized value!
void	WILDDetermineChunkRangeOfSubstringOfObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													struct LEOContext* inContext );
void		WILDGetObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, size_t startOffset, size_t endOffset, LEOValuePtr outValue, struct LEOContext* inContext );
void		WILDSetObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, LEOValuePtr inValue, size_t startOffset, size_t endOffset, struct LEOContext* inContext );

void		WILDCleanUpObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );


bool	WILDCanGetObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext );
LEOValuePtr	WILDGetObjectValueForKey( LEOValuePtr self, const char* keyName, union LEOValue* tempStorage, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );
size_t	WILDGetObjectKeyCount( LEOValuePtr self, struct LEOContext* inContext );



struct LEOValueType	kLeoValueTypeWILDObject =
{
	"object",
	sizeof(struct LEOValueObject),
	
	WILDGetObjectValueAsNumber,
	WILDGetObjectValueAsInteger,
	WILDGetObjectValueAsString,
	WILDGetObjectValueAsBoolean,
	WILDGetObjectValueAsRangeOfString,
	
	WILDSetObjectValueAsNumber,
	WILDSetObjectValueAsInteger,
	WILDSetObjectValueAsString,
	WILDSetObjectValueAsBoolean,
	WILDSetObjectValueRangeAsString,
	WILDSetObjectValuePredeterminedRangeAsString,
	
	WILDInitObjectValueCopy,
	WILDInitObjectValueSimpleCopy,
	WILDPutObjectValueIntoValue,
	LEOCantFollowReferencesAndReturnValueOfType,
	WILDDetermineChunkRangeOfSubstringOfObjectValue,
	
	WILDCleanUpObjectValue,
	
	WILDCanGetObjectValueAsNumber,
	
	WILDGetObjectValueForKey,
	LEOCantSetValueForKey,
	LEOSetStringLikeValueAsArray,
	WILDGetObjectKeyCount,
	
	WILDGetObjectValueForKeyOfRange,
	WILDSetObjectValueForKeyOfRange,
};




void	WILDInitObjectValue( struct LEOValueObject* inStorage, id<WILDObject> wildObject, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	inStorage->base.isa = &kLeoValueTypeWILDObject;
	if( keepReferences == kLEOInvalidateReferences )
		inStorage->base.refObjectID = kLEOObjectIDINVALID;
	inStorage->object = (void*)[wildObject retain];
}


LEONumber	WILDGetObjectValueAsNumber( LEOValuePtr self, LEOUnit *outUnit, struct LEOContext* inContext )
{
	char*		endPtr = NULL;
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return -1;
	}
	
	// Determine if there's a unit on this number, remove it but remember it:
	size_t		strLen = strlen(str);
	LEOUnit		theUnit = kLEOUnitNone;
	
	for( int x = 1; x < kLEOUnit_Last; x++ )	// Skip first one, which is empty string for 'no unit' and would match anything.
	{
		size_t	unitLen = strlen(gUnitLabels[x]);
		if( unitLen < strLen )
		{
			if( strcasecmp( str +(strLen -unitLen), gUnitLabels[x] ) == 0 )
			{
				strLen -= unitLen;
				theUnit = x;
				break;
			}
		}
	}

	LEONumber	num = strtod( str, &endPtr );
	if( endPtr != (str +strLen) )
		LEOCantGetValueAsNumber( self, outUnit, inContext );
	
	if( outUnit )
		*outUnit = theUnit;
	
	return num;
}


LEOInteger	WILDGetObjectValueAsInteger( LEOValuePtr self, LEOUnit *outUnit, struct LEOContext* inContext )
{
	char*		endPtr = NULL;
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return -1;
	}

	// Determine if there's a unit on this number, remove it but remember it:
	size_t		strLen = strlen(str);
	LEOUnit		theUnit = kLEOUnitNone;
	
	for( int x = 1; x < kLEOUnit_Last; x++ )	// Skip first one, which is empty string for 'no unit' and would match anything.
	{
		size_t	unitLen = strlen(gUnitLabels[x]);
		if( unitLen < strLen )
		{
			if( strcasecmp( str +(strLen -unitLen), gUnitLabels[x] ) == 0 )
			{
				strLen -= unitLen;
				theUnit = x;
				break;
			}
		}
	}

	LEOInteger	num = strtoll( str, &endPtr, 10 );
	if( endPtr != (str +strLen) )
		LEOCantGetValueAsInteger( self, outUnit, inContext );

	if( outUnit )
		*outUnit = theUnit;
	
	return num;
}


const char*	WILDGetObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, struct LEOContext* inContext )
{
	const char*		str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return NULL;
	}
	if( outBuf )
	{
		strncpy( outBuf, str, bufSize );
		return str;
	}
	else
		return str;
}


bool	WILDGetObjectValueAsBoolean( LEOValuePtr self, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return false;
	}
	if( strcasecmp( str, "true" ) == 0 )
		return true;
	else if( strcasecmp( str, "false" ) == 0 )
		return false;
	else
		return LEOCantGetValueAsBoolean( self, inContext );

}


void	WILDGetObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	size_t		outChunkStart = 0,
				outChunkEnd = 0,
				outDelChunkStart = 0,
				outDelChunkEnd = 0;
	LEOGetChunkRanges( str, inType,
						inRangeStart, inRangeEnd,
						&outChunkStart, &outChunkEnd,
						&outDelChunkStart, &outDelChunkEnd, inContext->itemDelimiter );
	size_t		len = outChunkEnd -outChunkStart;
	if( len > bufSize )
		len = bufSize -1;
	memmove( outBuf, str +outChunkStart, len );
	outBuf[len] = 0;
}


void	WILDSetObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, LEOUnit inUnit, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithFormat: @"%g%s", inNumber, gUnitLabels[inUnit]]] )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	WILDSetObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, LEOUnit inUnit, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithFormat: @"%lld%s", inNumber, gUnitLabels[inUnit]]] )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	WILDSetObjectValueAsString( LEOValuePtr self, const char* inBuf, size_t inBufLen, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [[[NSString alloc] initWithBytes: inBuf length:inBufLen encoding: NSUTF8StringEncoding] autorelease]] )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	WILDSetObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: inBoolean ? @"true" : @"false"] )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	WILDSetObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	size_t		outChunkStart = 0,
				outChunkEnd = 0,
				outDelChunkStart = 0,
				outDelChunkEnd = 0,
				inBufLen = inBuf ? strlen(inBuf) : 0,
				selfLen = strlen( str ),
				finalLen = 0;
	LEOGetChunkRanges( str, inType,
						inRangeStart, inRangeEnd,
						&outChunkStart, &outChunkEnd,
						&outDelChunkStart, &outDelChunkEnd, inContext->itemDelimiter );
	if( !inBuf )	// NULL string means 'delete'.
	{
		outChunkStart = outDelChunkStart;
		outChunkEnd = outDelChunkEnd;
	}
	size_t		chunkLen = outChunkEnd -outChunkStart;
	finalLen = selfLen -chunkLen +inBufLen;
		
	char*		newStr = calloc( finalLen +1, sizeof(char) );
	memmove( newStr, str, outChunkStart );	// Copy before chunk.
	if( inBufLen > 0 )
		memmove( newStr +outChunkStart, inBuf, inBufLen );	// Copy new value of chunk.
	memmove( newStr +outChunkStart +inBufLen, str +outChunkEnd, selfLen -outChunkEnd );	// Copy after chunk.
	newStr[finalLen] = 0;
	
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithUTF8String: newStr]] )
	{
		LEOContextStopWithError( inContext, "This object's contents can't be changed." );
	}

	free(newStr);
}


void	WILDSetObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	size_t		inBufLen = inBuf ? strlen(inBuf) : 0,
				selfLen = strlen( str ),
				finalLen = 0,
				chunkLen = inRangeEnd -inRangeStart;
	finalLen = selfLen -chunkLen +inBufLen;
		
	char*		newStr = calloc( finalLen +1, sizeof(char) );
	memmove( newStr, str, inRangeStart );	// Copy before chunk.
	if( inBufLen > 0 )
		memmove( newStr +inRangeStart, inBuf, inBufLen );	// Copy new value of chunk.
	memmove( newStr +inRangeStart +inBufLen, str +inRangeEnd, selfLen -inRangeEnd );	// Copy after chunk.
	newStr[finalLen] = 0;
	
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithUTF8String: newStr]] )
	{
		LEOContextStopWithError( inContext, "This object's contents can't be changed." );
	}

	free( newStr );
}


void	WILDInitObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	dest->base.isa = &kLeoValueTypeWILDObject;
	if( keepReferences == kLEOInvalidateReferences )
		dest->base.refObjectID = kLEOObjectIDINVALID;
	dest->object.object = (void*)[(id)self->object.object retain];
}


void	WILDInitObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	LEOInitStringValue( dest, str, strlen(str), keepReferences, inContext );
}


void	WILDPutObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, struct LEOContext* inContext )
{
	NSString*	str = [(id<WILDObject>)self->object.object textContents];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}

	LEOSetValueAsString( dest, [str UTF8String], [str lengthOfBytesUsingEncoding: NSUTF8StringEncoding], inContext );
}


void	WILDDetermineChunkRangeOfSubstringOfObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	size_t		maxOffs = *ioBytesEnd -((size_t)str);
	str += (*ioBytesStart);
	
	size_t		chunkStart, chunkEnd, delChunkStart, delChunkEnd;
	
	LEOGetChunkRanges( str, inType,
						inRangeStart, inRangeEnd,
						&chunkStart, &chunkEnd,
						&delChunkStart, &delChunkEnd,
						inContext->itemDelimiter );
	if( chunkStart > maxOffs )
		chunkStart = maxOffs;
	if( chunkEnd > maxOffs )
		chunkEnd = maxOffs;
	(*ioBytesStart) += chunkStart;
	(*ioBytesEnd) = (*ioBytesStart) + (chunkEnd -chunkStart);
	if( delChunkStart > maxOffs )
		delChunkStart = maxOffs;
	if( delChunkEnd > maxOffs )
		delChunkEnd = maxOffs;
	(*ioBytesDelStart) = (*ioBytesStart) +delChunkStart;
	(*ioBytesDelEnd) = (*ioBytesDelStart) + (delChunkEnd -delChunkStart);
}


void	WILDCleanUpObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	self->base.isa = NULL;
	if( self->object.object )
		[(id<NSObject>)self->object.object release];
	self->object.object = nil;
	if( keepReferences == kLEOInvalidateReferences && self->base.refObjectID != kLEOObjectIDINVALID )
	{
		LEOContextGroupRecycleObjectID( inContext->group, self->base.refObjectID );
		self->base.refObjectID = 0;
	}
}


bool	WILDCanGetObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext )
{
	const char*		str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return false;
	}
	
	for( size_t x = 0; str[x] != 0; x++ )
	{
		if( str[x] < '0' || str[x] > '9' )
			return false;
	}
	
	return true;
}


LEOValuePtr	WILDGetObjectValueForKey( LEOValuePtr self, const char* keyName, union LEOValue* tempStorage, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	return NULL;
}


size_t	WILDGetObjectKeyCount( LEOValuePtr self, struct LEOContext* inContext )
{
	return 0;
}


void		WILDGetObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, size_t startOffset, size_t endOffset, LEOValuePtr outValue, struct LEOContext* inContext )
{
	id<WILDObject>		theObject = (id<WILDObject>) self->object.object;
	
	id	returnValue = [theObject valueForWILDPropertyNamed: [NSString stringWithUTF8String: keyName] ofRange: NSMakeRange(startOffset, endOffset)];	// TODO: Need to convert the range into character index, is a UTF8 byte index ATM.
	
	if( returnValue == NULL )
		LEOContextStopWithError( inContext, "No property \"%s\".", keyName );
	else
		WILDObjCObjectToLEOValue( returnValue, outValue, inContext );
}


void		WILDSetObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, LEOValuePtr inValue, size_t startOffset, size_t endOffset, struct LEOContext* inContext )
{
	id<WILDObject>		theObject = (id<WILDObject>) self->object.object;
	NSString		*	theKeyName = [NSString stringWithUTF8String: keyName];
	LEOValueTypePtr		desiredType = [theObject typeForWILDPropertyNamed: theKeyName];
	id					sourceValue = desiredType ? WILDObjCObjectFromLEOValue( inValue, inContext, desiredType ) : nil;
	if( !desiredType )
		LEOContextStopWithError( inContext, "Unexpected %s.", inValue->base.isa->displayTypeName );
	else if( !sourceValue )
		LEOContextStopWithError( inContext, "Expected %s found %s.", desiredType->displayTypeName, inValue->base.isa->displayTypeName );
	
	if( ![theObject setValue: sourceValue forWILDPropertyNamed: theKeyName inRange: NSMakeRange(startOffset, endOffset-startOffset)] )	// TODO: Need to convert the range into character index, is a UTF8 byte index ATM.
		LEOContextStopWithError( inContext, "No property \"%s\".", keyName );
}


struct LEOScript*	WILDGetParentScript( struct LEOScript* inScript, struct LEOContext* inContext )
{
	struct LEOScript*	theScript = NULL;
	id<WILDObject>		theObject = nil;
	LEOValuePtr			theObjectVal = LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, inScript->ownerObject, inScript->ownerObjectSeed );
	if( theObjectVal )
		theObject = (id<WILDObject>) theObjectVal->object.object;
	
	if( theObject != nil )
		theScript = [[theObject parentObject] scriptObjectShowingErrorMessage: YES];
	
	return theScript;
}

id<WILDObject>		WILDGetOwnerObjectFromContext( struct LEOContext * inContext )
{
	LEOScript	*	script = LEOContextPeekCurrentScript( inContext );
	LEOValuePtr		owner = LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, script->ownerObject, script->ownerObjectSeed );
	if( !owner )
		return nil;
	return (id<WILDObject>) owner->object.object;
}




