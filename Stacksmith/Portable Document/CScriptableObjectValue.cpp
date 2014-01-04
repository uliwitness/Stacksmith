//
//  CScriptableObjectValue.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "CScriptableObjectValue.h"
#include "LEOInterpreter.h"
#include "LEOContextGroup.h"
#include "LEOScript.h"
#include <sstream>


using namespace Calhoun;


LEONumber	GetScriptableObjectValueAsNumber( LEOValuePtr self, LEOUnit* inUnit, LEOContext* inContext );

LEOInteger	GetScriptableObjectValueAsInteger( LEOValuePtr self, LEOUnit* inUnit, LEOContext* inContext );

const char*	GetScriptableObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, LEOContext* inContext );

bool		GetScriptableObjectValueAsBoolean( LEOValuePtr self, LEOContext* inContext );

void		GetScriptableObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, LEOContext* inContext );

void	SetScriptableObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, LEOUnit inUnit, LEOContext* inContext );
void	SetScriptableObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, LEOUnit inUnit, LEOContext* inContext );
void	SetScriptableObjectValueAsString( LEOValuePtr self, const char* inBuf, size_t inBufLen, LEOContext* inContext );
void	SetScriptableObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, LEOContext* inContext );
void	SetScriptableObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, LEOContext* inContext );
void	SetScriptableObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, LEOContext* inContext );
void	InitScriptableObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );	// dest is an uninitialized value.
void	InitScriptableObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );	// dest is an uninitialized value.
void	PutScriptableObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, LEOContext* inContext );	// dest must be a VALID, initialized value!
void	DetermineChunkRangeOfSubstringOfScriptableObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													LEOContext* inContext );
void		GetScriptableObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, size_t startOffset, size_t endOffset, LEOValuePtr outValue, LEOContext* inContext );
void		SetScriptableObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, LEOValuePtr inValue, size_t startOffset, size_t endOffset, LEOContext* inContext );

void		CleanUpScriptableObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );


bool	CanGetScriptableObjectValueAsNumber( LEOValuePtr self, LEOContext* inContext );
LEOValuePtr	GetScriptableObjectValueForKey( LEOValuePtr self, const char* keyName, union LEOValue* tempStorage, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
size_t	GetScriptableObjectKeyCount( LEOValuePtr self, LEOContext* inContext );



struct LEOValueType	kLeoValueTypeScriptableObject =
{
	"object",
	sizeof(struct LEOValueObject),
	
	GetScriptableObjectValueAsNumber,
	GetScriptableObjectValueAsInteger,
	GetScriptableObjectValueAsString,
	GetScriptableObjectValueAsBoolean,
	GetScriptableObjectValueAsRangeOfString,
	
	SetScriptableObjectValueAsNumber,
	SetScriptableObjectValueAsInteger,
	SetScriptableObjectValueAsString,
	SetScriptableObjectValueAsBoolean,
	SetScriptableObjectValueRangeAsString,
	SetScriptableObjectValuePredeterminedRangeAsString,
	
	InitScriptableObjectValueCopy,
	InitScriptableObjectValueSimpleCopy,
	PutScriptableObjectValueIntoValue,
	LEOCantFollowReferencesAndReturnValueOfType,
	DetermineChunkRangeOfSubstringOfScriptableObjectValue,
	
	CleanUpScriptableObjectValue,
	
	CanGetScriptableObjectValueAsNumber,
	
	GetScriptableObjectValueForKey,
	LEOCantSetValueForKey,
	LEOSetStringLikeValueAsArray,
	GetScriptableObjectKeyCount,
	
	GetScriptableObjectValueForKeyOfRange,
	SetScriptableObjectValueForKeyOfRange,
};




void	CScriptableObject::InitScriptableObjectValue( LEOValueObject* inStorage, CScriptableObject* wildObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	inStorage->base.isa = &kLeoValueTypeScriptableObject;
	if( keepReferences == kLEOInvalidateReferences )
		inStorage->base.refObjectID = kLEOObjectIDINVALID;
	inStorage->object = (void*)wildObject->Retain();
}


LEONumber	GetScriptableObjectValueAsNumber( LEOValuePtr self, LEOUnit *outUnit, LEOContext* inContext )
{
	char*		endPtr = NULL;
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return -1;
	}
	
	// Determine if there's a unit on this number, remove it but remember it:
	size_t		strLen = txt.size();
	const char*	str = txt.c_str();
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


LEOInteger	GetScriptableObjectValueAsInteger( LEOValuePtr self, LEOUnit *outUnit, LEOContext* inContext )
{
	char*		endPtr = NULL;
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return -1;
	}

	// Determine if there's a unit on this number, remove it but remember it:
	size_t		strLen = txt.size();
	const char*	str = txt.c_str();
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


const char*	GetScriptableObjectValueAsString( LEOValuePtr self, char* outBuf, size_t bufSize, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return NULL;
	}
	const char*	str = txt.c_str();
	if( outBuf )
	{
		strncpy( outBuf, str, bufSize );
		return str;
	}
	else
		return str;
}


bool	GetScriptableObjectValueAsBoolean( LEOValuePtr self, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return false;
	}
	const char*	str = txt.c_str();
	if( strcasecmp( str, "true" ) == 0 )
		return true;
	else if( strcasecmp( str, "false" ) == 0 )
		return false;
	else
		return LEOCantGetValueAsBoolean( self, inContext );

}


void	GetScriptableObjectValueAsRangeOfString( LEOValuePtr self, LEOChunkType inType,
										size_t inRangeStart, size_t inRangeEnd,
										char* outBuf, size_t bufSize, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	const char*	str = txt.c_str();
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


void	SetScriptableObjectValueAsNumber( LEOValuePtr self, LEONumber inNumber, LEOUnit inUnit, LEOContext* inContext )
{
	std::stringstream	sstream;
	sstream << inNumber << gUnitLabels[inUnit];
	if( !((CScriptableObject*)self->object.object)->SetTextContents( sstream.str().c_str() ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, LEOUnit inUnit, LEOContext* inContext )
{
	std::stringstream	sstream;
	sstream << inNumber << gUnitLabels[inUnit];
	if( !((CScriptableObject*)self->object.object)->SetTextContents(sstream.str()) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsString( LEOValuePtr self, const char* inBuf, size_t inBufLen, LEOContext* inContext )
{
	std::string		txt( inBuf, inBufLen );
	if( !((CScriptableObject*)self->object.object)->SetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, LEOContext* inContext )
{
	if( !((CScriptableObject*)self->object.object)->SetTextContents( inBoolean ? "true" : "false" ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	size_t		outChunkStart = 0,
				outChunkEnd = 0,
				outDelChunkStart = 0,
				outDelChunkEnd = 0,
				inBufLen = inBuf ? strlen(inBuf) : 0,
				selfLen = txt.size(),
				finalLen = 0;
	const char*	str = txt.c_str();
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
		
	char*		newStr = (char*) calloc( finalLen +1, sizeof(char) );
	memmove( newStr, str, outChunkStart );	// Copy before chunk.
	if( inBufLen > 0 )
		memmove( newStr +outChunkStart, inBuf, inBufLen );	// Copy new value of chunk.
	memmove( newStr +outChunkStart +inBufLen, str +outChunkEnd, selfLen -outChunkEnd );	// Copy after chunk.
	newStr[finalLen] = 0;
	
	if( !((CScriptableObject*)self->object.object)->SetTextContents(newStr) )
	{
		LEOContextStopWithError( inContext, "This object's contents can't be changed." );
	}

	free(newStr);
}


void	SetScriptableObjectValuePredeterminedRangeAsString( LEOValuePtr self,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	const char*	str = txt.c_str();
	size_t		inBufLen = inBuf ? strlen(inBuf) : 0,
				selfLen = strlen( str ),
				finalLen = 0,
				chunkLen = inRangeEnd -inRangeStart;
	finalLen = selfLen -chunkLen +inBufLen;
		
	char*		newStr = (char*) calloc( finalLen +1, sizeof(char) );
	memmove( newStr, str, inRangeStart );	// Copy before chunk.
	if( inBufLen > 0 )
		memmove( newStr +inRangeStart, inBuf, inBufLen );	// Copy new value of chunk.
	memmove( newStr +inRangeStart +inBufLen, str +inRangeEnd, selfLen -inRangeEnd );	// Copy after chunk.
	newStr[finalLen] = 0;
	
	if( !((CScriptableObject*)self->object.object)->SetTextContents(newStr) )
	{
		LEOContextStopWithError( inContext, "This object's contents can't be changed." );
	}

	free( newStr );
}


void	InitScriptableObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	dest->base.isa = &kLeoValueTypeScriptableObject;
	if( keepReferences == kLEOInvalidateReferences )
		dest->base.refObjectID = kLEOObjectIDINVALID;
	dest->object.object = (void*)((CScriptableObject*)self->object.object)->Retain();
}


void	InitScriptableObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	LEOInitStringValue( dest, txt.c_str(), txt.size(), keepReferences, inContext );
}


void	PutScriptableObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}

	LEOSetValueAsString( dest, txt.c_str(), txt.size(), inContext );
}


void	DetermineChunkRangeOfSubstringOfScriptableObjectValue( LEOValuePtr self, size_t *ioBytesStart, size_t *ioBytesEnd,
													size_t *ioBytesDelStart, size_t *ioBytesDelEnd,
													LEOChunkType inType, size_t inRangeStart, size_t inRangeEnd,
													LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return;
	}
	const char*	str = txt.c_str();
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


void	CleanUpScriptableObjectValue( LEOValuePtr self, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	self->base.isa = NULL;
	if( self->object.object )
		((CScriptableObject*)self->object.object)->Release();
	self->object.object = NULL;
	if( keepReferences == kLEOInvalidateReferences && self->base.refObjectID != kLEOObjectIDINVALID )
	{
		LEOContextGroupRecycleObjectID( inContext->group, self->base.refObjectID );
		self->base.refObjectID = 0;
	}
}


bool	CanGetScriptableObjectValueAsNumber( LEOValuePtr self, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		LEOContextStopWithError( inContext, "This object can have no contents." );
		return false;
	}
	
	for( size_t x = 0; x < txt.size(); x++ )
	{
		if( txt[x] < '0' || txt[x] > '9' )
			return false;
	}
	
	return true;
}


LEOValuePtr	GetScriptableObjectValueForKey( LEOValuePtr self, const char* keyName, union LEOValue* tempStorage, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	return NULL;
}


size_t	GetScriptableObjectKeyCount( LEOValuePtr self, LEOContext* inContext )
{
	return 0;
}


void		GetScriptableObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, size_t startOffset, size_t endOffset, LEOValuePtr outValue, LEOContext* inContext )
{
	CScriptableObject*		theObject = (CScriptableObject*)self->object.object;
	
	if( !theObject->GetPropertyNamed( keyName, startOffset, endOffset, outValue ) )
		LEOContextStopWithError( inContext, "No property \"%s\".", keyName );
}


void		SetScriptableObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, LEOValuePtr inValue, size_t startOffset, size_t endOffset, LEOContext* inContext )
{
	CScriptableObject*	theObject = (CScriptableObject*)self->object.object;
	theObject->SetValueForPropertyNamed( inValue, keyName, startOffset, endOffset );
}


LEOScript*	CScriptableObject::GetParentScript( LEOScript* inScript, LEOContext* inContext )
{
	struct LEOScript*	theScript = NULL;
	CScriptableObject*	theObject = NULL;
	LEOValuePtr			theObjectVal = (LEOValuePtr)LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, inScript->ownerObject, inScript->ownerObjectSeed );
	if( theObjectVal )
		theObject = (CScriptableObject*) theObjectVal->object.object;
	
	if( theObject != NULL )
	{
		theScript = theObject->GetParentObject()->GetScriptObject([](const char * errMsg, size_t errLine, size_t errOffs, CScriptableObject * owner)
		{
			printf("%s\n",errMsg);
		});
	}
	
	return theScript;
}

CScriptableObject*		CScriptableObject::GetOwnerScriptableObjectFromContext( LEOContext * inContext )
{
	LEOScript	*	script = LEOContextPeekCurrentScript( inContext );
	LEOValuePtr		owner = (LEOValuePtr) LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, script->ownerObject, script->ownerObjectSeed );
	if( !owner )
		return NULL;
	return (CScriptableObject*) owner->object.object;
}




