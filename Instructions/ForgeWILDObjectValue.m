//
//  ForgeWILDObjectValue.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "ForgeWILDObjectValue.h"
#include "LEOInterpreter.h"
#include "LEOContextGroup.h"
#include "LEOScript.h"


LEONumber	LEOGetWILDObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext );

LEOInteger	LEOGetWILDObjectValueAsInteger( LEOValuePtr self, struct LEOContext* inContext );

void		LEOGetWILDObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, struct LEOContext* inContext );

bool		LEOGetWILDObjectValueAsBoolean( LEOValuePtr self, struct LEOContext* inContext );

void		LEOGetWILDObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, struct LEOContext* inContext );

void	LEOSetWILDObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, struct LEOContext* inContext );
void	LEOSetWILDObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, struct LEOContext* inContext );
void	LEOSetWILDObjectValueAsString( LEOValuePtr self, const char* inBuf, struct LEOContext* inContext );
void	LEOSetWILDObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, struct LEOContext* inContext );
void	LEOSetWILDObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext );
void	LEOSetWILDObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext );
void	LEOInitWILDObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );	// dest is an uninitialized value.
void	LEOInitWILDObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );	// dest is an uninitialized value.
void	LEOPutWILDObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, struct LEOContext* inContext );	// dest must be a VALID, initialized value!
void	LEODetermineChunkRangeOfSubstringOfWILDObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													struct LEOContext* inContext );
void	LEOCleanUpWILDObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext );


bool	LEOCanGetWILDObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext );
LEOValuePtr	LEOGetWILDObjectValueForKey( LEOValuePtr self, const char* keyName, struct LEOContext* inContext );
size_t	LEOGetWILDObjectKeyCount( LEOValuePtr self, struct LEOContext* inContext );



struct LEOValueType	kLeoValueTypeWILDObject =
{
	"object",
	sizeof(struct LEOValueObject),
	
	LEOGetWILDObjectValueAsNumber,
	LEOGetWILDObjectValueAsInteger,
	LEOGetWILDObjectValueAsString,
	LEOGetWILDObjectValueAsBoolean,
	LEOGetWILDObjectValueAsRangeOfString,
	
	LEOSetWILDObjectValueAsNumber,
	LEOSetWILDObjectValueAsInteger,
	LEOSetWILDObjectValueAsString,
	LEOSetWILDObjectValueAsBoolean,
	LEOSetWILDObjectValueRangeAsString,
	LEOSetWILDObjectValuePredeterminedRangeAsString,
	
	LEOInitWILDObjectValueCopy,
	LEOInitWILDObjectValueSimpleCopy,
	LEOPutWILDObjectValueIntoValue,
	LEOCantFollowReferencesAndReturnValueOfType,
	LEODetermineChunkRangeOfSubstringOfWILDObjectValue,
	
	LEOCleanUpWILDObjectValue,
	
	LEOCanGetWILDObjectValueAsNumber,
	
	LEOGetWILDObjectValueForKey,
	LEOCantSetValueForKey,
	LEOSetStringLikeValueAsArray,
	LEOGetWILDObjectKeyCount
};




void	LEOInitWILDObjectValue( LEOValuePtr inStorage, id<WILDObject> wildObject, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	inStorage->base.isa = &kLeoValueTypeWILDObject;
	if( keepReferences == kLEOInvalidateReferences )
		inStorage->base.refObjectID = kLEOObjectIDINVALID;
	inStorage->object.object = (void*)[wildObject retain];
}


LEONumber	LEOGetWILDObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext )
{
	char*		endPtr = NULL;
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	LEONumber	num = strtod( str, &endPtr );
	if( endPtr != (str +strlen(str)) )
		LEOCantGetValueAsNumber( self, inContext );
	return num;
}


LEOInteger	LEOGetWILDObjectValueAsInteger( LEOValuePtr self, struct LEOContext* inContext )
{
	char*		endPtr = NULL;
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	LEOInteger	num = strtoll( str, &endPtr, 10 );
	if( endPtr != (str +strlen(str)) )
		LEOCantGetValueAsInteger( self, inContext );
	return num;
}


void	LEOGetWILDObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, struct LEOContext* inContext )
{
	const char*		str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	strncpy( outBuf, str, bufSize );
}


bool	LEOGetWILDObjectValueAsBoolean( LEOValuePtr self, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	if( strcasecmp( str, "true" ) == 0 )
		return true;
	else if( strcasecmp( str, "false" ) == 0 )
		return false;
	else
		return LEOCantGetValueAsBoolean( self, inContext );

}


void	LEOGetWILDObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
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


void	LEOSetWILDObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithFormat: @"%g", inNumber]] )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
	}
}


void	LEOSetWILDObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithFormat: @"%lld", inNumber]] )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
	}
}


void	LEOSetWILDObjectValueAsString( LEOValuePtr self, const char* inBuf, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: [NSString stringWithUTF8String: inBuf]] )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
	}
}


void	LEOSetWILDObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, struct LEOContext* inContext )
{
	if( ![(id<WILDObject>)self->object.object setTextContents: inBoolean ? @"true" : @"false"] )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
	}
}


void	LEOSetWILDObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
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
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object's contents can't be changed." );
		inContext->keepRunning = false;
	}

	free(newStr);
}


void	LEOSetWILDObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
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
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object's contents can't be changed." );
		inContext->keepRunning = false;
	}

	free( newStr );
}


void	LEOInitWILDObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	dest->base.isa = &kLeoValueTypeWILDObject;
	if( keepReferences == kLEOInvalidateReferences )
		dest->base.refObjectID = kLEOObjectIDINVALID;
	dest->object.object = (void*)[(id)self->object.object retain];
}


void	LEOInitWILDObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	LEOInitStringValue( dest, str, strlen(str), keepReferences, inContext );
}


void	LEOPutWILDObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, struct LEOContext* inContext )
{
	const char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}

	LEOSetValueAsString( dest, str, inContext );
}


void	LEODetermineChunkRangeOfSubstringOfWILDObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													struct LEOContext* inContext )
{
	char*	str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
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


void	LEOCleanUpWILDObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, struct LEOContext* inContext )
{
	self->base.isa = NULL;
	if( self->object.object )
		[self->object.object release];
	self->object.object = nil;
	if( keepReferences == kLEOInvalidateReferences && self->base.refObjectID != kLEOObjectIDINVALID )
	{
		LEOContextGroupRecycleObjectID( inContext->group, self->base.refObjectID );
		self->base.refObjectID = 0;
	}
}


bool	LEOCanGetWILDObjectValueAsNumber( LEOValuePtr self, struct LEOContext* inContext )
{
	char*		str = [[(id<WILDObject>)self->object.object textContents] UTF8String];
	if( !str )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "This object can have no contents." );
		inContext->keepRunning = false;
		return;
	}
	
	for( size_t x = 0; str[x] != 0; x++ )
	{
		if( str[x] < '0' || str[x] > '9' )
			return false;
	}
	
	return true;
}


LEOValuePtr	LEOGetWILDObjectValueForKey( LEOValuePtr self, const char* keyName, struct LEOContext* inContext )
{
	return NULL;
}


size_t	LEOGetWILDObjectKeyCount( LEOValuePtr self, struct LEOContext* inContext )
{
	return 0;
}


struct LEOScript*	LEOForgeScriptGetParentScript( struct LEOScript* inScript, struct LEOContext* inContext )
{
	struct LEOScript*	theScript = NULL;
	LEOValuePtr			theObjectVal = LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, inScript->ownerObject, inScript->ownerObjectSeed );
	id<WILDObject>	theObject = (id<WILDObject>) theObjectVal->object.object;
	
	if( theObject != nil )
		theScript = [[theObject parentObject] scriptObjectShowingErrorMessage: YES];
	
	return theScript;
}





