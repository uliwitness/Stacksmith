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
#include "CCancelPolling.h"
#include "CStack.h"
#include "CString.h"
#include <sstream>
#include <iostream>
#include "CAlert.h"


using namespace Carlson;


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

void	ScriptableObjectCallNonexistentHandler( LEOContext* inContext, LEOHandlerID inHandler, TMayGoUnhandledFlag mayGoUnhandled );



struct LEOValueType	Carlson::kLeoValueTypeScriptableObject =
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

	LEOCantSetValueAsNativeObject,
	
	LEOSetStringLikeValueAsRect,
	LEOGetStringLikeValueAsRect,
	LEOSetStringLikeValueAsPoint,
	LEOGetStringLikeValueAsPoint,
	
	LEOValueIsNotUnset,
	
	LEOSetStringLikeValueAsRange,
	LEOGetStringLikeValueAsRange
};




void	CScriptableObject::InitScriptableObjectValue( LEOValueObject* inStorage, CScriptableObject* wildObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	inStorage->base.isa = &kLeoValueTypeScriptableObject;
	if( keepReferences == kLEOInvalidateReferences )
		inStorage->base.refObjectID = kLEOObjectIDINVALID;
	inStorage->object = (void*)wildObject;	// We don't retain here, as all native objects create one 'canonical' mValueForScripts ivar that would lead to a retain circle. Keep references to that object, which will get invalidated when the object goes away.
}


LEONumber	GetScriptableObjectValueAsNumber( LEOValuePtr self, LEOUnit *outUnit, LEOContext* inContext )
{
	char*		endPtr = NULL;
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
	CString*	txt = new CString;	// So we can return a pointer to our c_str() which stays valid beyond this function's lifetime.
	txt->Autorelease();
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt->GetString() ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
		return NULL;
	}
	const char*	str = txt->GetString().c_str();
	if( outBuf && str )
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsInteger( LEOValuePtr self, LEOInteger inNumber, LEOUnit inUnit, LEOContext* inContext )
{
	std::stringstream	sstream;
	sstream << inNumber << gUnitLabels[inUnit];
	if( !((CScriptableObject*)self->object.object)->SetTextContents(sstream.str()) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsString( LEOValuePtr self, const char* inBuf, size_t inBufLen, LEOContext* inContext )
{
	std::string		txt( inBuf, inBufLen );
	if( !((CScriptableObject*)self->object.object)->SetTextContents( txt ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueAsBoolean( LEOValuePtr self, bool inBoolean, LEOContext* inContext )
{
	if( !((CScriptableObject*)self->object.object)->SetTextContents( inBoolean ? "true" : "false" ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
	}
}


void	SetScriptableObjectValueRangeAsString( LEOValuePtr self, LEOChunkType inType,
								size_t inRangeStart, size_t inRangeEnd,
								const char* inBuf, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object's contents can't be changed." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object's contents can't be changed." );
	}

	free( newStr );
}


void	InitScriptableObjectValueCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	dest->base.isa = &kLeoValueTypeScriptableObject;
	if( keepReferences == kLEOInvalidateReferences )
		dest->base.refObjectID = kLEOObjectIDINVALID;
	dest->object.object = self->object.object;	// We don't retain this. See InitScriptableObjectValue() for details.
}


void	InitScriptableObjectValueSimpleCopy( LEOValuePtr self, LEOValuePtr dest, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
		return;
	}
	LEOInitStringValue( dest, txt.c_str(), txt.size(), keepReferences, inContext );
}


void	PutScriptableObjectValueIntoValue( LEOValuePtr self, LEOValuePtr dest, LEOContext* inContext )
{
	std::string	txt;
	if( !((CScriptableObject*)self->object.object)->GetTextContents( txt ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
	self->object.object = NULL;	// We don't retain it to avoid circles, so we don't release it here.
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "This object can have no contents." );
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
	
	if( !theObject->GetPropertyNamed( keyName, startOffset, endOffset, inContext, outValue ) )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "No property \"%s\".", keyName );
	}
}


void		SetScriptableObjectValueForKeyOfRange( LEOValuePtr self, const char* keyName, LEOValuePtr inValue, size_t startOffset, size_t endOffset, LEOContext* inContext )
{
	CScriptableObject*	theObject = (CScriptableObject*)self->object.object;
	theObject->SetValueForPropertyNamed( inValue, inContext, keyName, startOffset, endOffset );
}


void	ScriptableObjectCallNonexistentHandler( LEOContext* inContext, LEOHandlerID inHandler, TMayGoUnhandledFlag mayGoUnhandled )
{
	bool			handled = false;
	LEOHandlerID	arrowKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "arrowKey" );
	LEOHandlerID	forwardDeleteKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "forwardDelete" );
	LEOHandlerID	backspaceKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "backspaceKey" );
	LEOHandlerID	keyDownHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "keyDown" );
	LEOHandlerID	tabKeyHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "tabKey" );
	LEOHandlerID	pointerDownHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseDownWhileEditing" );
	LEOHandlerID	pointerDoubleUpHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseDoubleClickWhileEditing" );
	LEOHandlerID	pointerDragHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseDragWhileEditing" );
	LEOHandlerID	peekingDownHandlerID = LEOContextGroupHandlerIDForHandlerName( inContext->group, "mouseDownWhilePeeking" );
	if( inHandler == arrowKeyHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		LEOValuePtr	directionParam = LEOGetParameterAtIndexFromEndOfStack( inContext, 1 );
		char		buf[40] = {};
		if( directionParam )
		{
			const char*	directionStr = LEOGetValueAsString( directionParam, buf, sizeof(buf), inContext );
			if( strcasecmp( directionStr, "left") == 0 )
			{
				userData->GetStack()->GetPreviousCard()->GoThereInNewWindow( EOpenInSameWindow, userData->GetStack(), NULL, [](){  }, "", EVisualEffectSpeedNormal );
				handled = true;
			}
			else if( strcasecmp( directionStr, "right") == 0 )
			{
				userData->GetStack()->GetNextCard()->GoThereInNewWindow( EOpenInSameWindow, userData->GetStack(), NULL, [](){  }, "", EVisualEffectSpeedNormal );
				handled = true;
			}
			else if( strcasecmp( directionStr, "up") == 0 )
			{
				userData->GetStack()->GetCard( 0 )->GoThereInNewWindow( EOpenInSameWindow, userData->GetStack(), NULL, [](){  }, "", EVisualEffectSpeedNormal );
				handled = true;
			}
			else if( strcasecmp( directionStr, "down") == 0 )
			{
				userData->GetStack()->GetCard( userData->GetStack()->GetNumCards() -1 )->GoThereInNewWindow( EOpenInSameWindow, userData->GetStack(), NULL, [](){  }, "", EVisualEffectSpeedNormal );
				handled = true;
			}
		}
		else
			handled = false;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == tabKeyHandlerID )
	{
		LEOValuePtr	shiftModifierParam = LEOGetParameterAtIndexFromEndOfStack( inContext, 1 );
		char		buf[40] = {};
		if( shiftModifierParam )
		{
			const char*	directionStr = LEOGetValueAsString( shiftModifierParam, buf, sizeof(buf), inContext );
			if( strcasecmp( directionStr, "shift") == 0 )
			{
				// +++ Backwards tab.
				handled = true;
			}
			else if( directionStr[0] == 0 )
			{
				// +++ Regular tab.
				handled = true;
			}
		}
		else
			handled = false;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == backspaceKeyHandlerID || inHandler == forwardDeleteKeyHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		if( !userData->GetStack()->GetEditingBackground() )
			userData->GetStack()->GetCurrentCard()->DeleteSelectedItem();
		userData->GetStack()->GetCurrentCard()->GetBackground()->DeleteSelectedItem();
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == keyDownHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		LEOValuePtr	directionParam = LEOGetParameterAtIndexFromEndOfStack( inContext, 1 );
		char		buf[40] = {};
		if( directionParam )
		{
			const char*	directionStr = LEOGetValueAsString( directionParam, buf, sizeof(buf), inContext );
			if( strcasecmp( directionStr, "\r") == 0 )
			{
				userData->GetStack()->GetCurrentCard()->TriggerDefaultButton();
			}
			handled = true;
			LEOCleanUpHandlerParametersFromEndOfStack( inContext );
		}
	}
	else if( inHandler == peekingDownHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		CConcreteObject*		so = dynamic_cast<CConcreteObject*>( userData->GetTarget() );
		userData->GetStack()->ShowScriptEditorForObject( so );
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == pointerDoubleUpHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		CConcreteObject*		so = dynamic_cast<CConcreteObject*>( userData->GetTarget() );
		userData->GetStack()->ShowPropertyEditorForObject( so );
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == pointerDownHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		CPart*					so = dynamic_cast<CPart*>( userData->GetTarget() );
		if( so )
		{
			LEOValuePtr	buttonNumberParam = LEOGetParameterAtIndexFromEndOfStack( inContext, 1 );
			if( buttonNumberParam )
			{
				LEOUnit		theUnit = kLEOUnitNone;
				LEOInteger	buttonNumber = LEOGetValueAsInteger( buttonNumberParam, &theUnit, inContext );
				if( buttonNumber == 2 )
				{
					userData->GetStack()->ShowContextualMenuForObject( so );
				}
			}
		}
		
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( inHandler == pointerDragHandlerID )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		CPart*		so = dynamic_cast<CPart*>( userData->GetTarget() );
		if( so )
		{
			LEOInteger	customPartIndex = -1;
			LEONumber 	x = 0;
			LEONumber 	y = 0;
			CStack*	theStack = so->GetStack();
			theStack->GetMousePosition( &x, &y );
						
			THitPart	hitPart = so->HitTestForEditing( x, y, EHitTestHandlesToo, &customPartIndex );
			if( hitPart != ENothingHitPart )
			{
				so->Grab( hitPart, customPartIndex, [theStack](long long inGuidelineCoord,TGuidelineCallbackAction action)
				{
					if( action == EGuidelineCallbackActionClearAllDone
						|| action == EGuidelineCallbackActionClearAllForFilling )
					{
						theStack->ClearAllGuidelines( action == EGuidelineCallbackActionClearAllDone );
					}
					else
					{
						theStack->AddGuideline( inGuidelineCoord, action == EGuidelineCallbackActionAddHorizontal );
					}
				} );
			}
		}
		
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	else if( mayGoUnhandled == EMayGoUnhandled )
	{
		handled = true;
		LEOCleanUpHandlerParametersFromEndOfStack( inContext );
	}
	
	if( !handled )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Couldn't find a handler for %s.", LEOContextGroupHandlerNameForHandlerID( inContext->group, inHandler ) );
	}
}


LEOScript*	CScriptableObject::GetParentScript( LEOScript* inScript, LEOContext* inContext, void* inParam )
{
	struct LEOScript*	theScript = NULL;
	CScriptableObject*	theObject = NULL;
	LEOValuePtr			theObjectVal = (LEOValuePtr)LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, inScript->ownerObject, inScript->ownerObjectSeed );
	if( theObjectVal )
		theObject = (CScriptableObject*) theObjectVal->object.object;
	
	if( theObject != NULL )
	{
		//printf( "Going up to parent %s\n", typeid(*theObject).name() );
		
		CScriptableObject*	scriptableParent = theObject->GetParentObject( (CScriptableObject*)inParam );
		if( scriptableParent )
		{
			theScript = scriptableParent->GetScriptObject([](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); });
		}
	}
	
	return theScript;
}

CScriptableObject*		CScriptableObject::GetOwnerScriptableObjectFromContext( LEOContext * inContext )
{
	LEOScript	*	script = LEOContextPeekCurrentScript( inContext );
    if( !script )
        return NULL;
	LEOValuePtr		owner = (LEOValuePtr) LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, script->ownerObject, script->ownerObjectSeed );
	if( !owner )
		return NULL;
	return (CScriptableObject*) owner->object.object;
}


void	CScriptableObject::PreInstructionProc( LEOContext* inContext )
{
	if( CCancelPolling::GetUserWantsToCancel() )
		inContext->flags &= ~kLEOContextKeepRunning;
	else
		LEORemoteDebuggerPreInstructionProc( inContext );
}


void	CScriptableObject::ContextCompletedProc( LEOContext *ctx )
{
    CScriptableObject * me = ((CScriptContextUserData*)ctx->userData)->GetOwner();  // Can't use GetOwnerScriptableObjectFromContext() because that looks at the call stack, which is empty by now.
    if( me )
        me->ContextCompleted( ctx );
}


bool	CScriptableObject::HasOrInheritsMessageHandler( const char* inMsgName, CScriptableObject* previousParent )
{
	LEOScript*	theScript = GetScriptObject(NULL);
	if( theScript )
	{
		LEOContextGroup*	contextGroup = GetScriptContextGroupObject();
		LEOHandlerID		handlerID = LEOContextGroupHandlerIDForHandlerName( contextGroup, inMsgName );
		if( handlerID != kLEOHandlerIDINVALID )
		{
			LEOHandler*	foundHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );
		
			if( foundHandler != NULL )
				return true;
		}
	}
	
	CScriptableObject	* parent = GetParentObject( previousParent );
	if( !parent )
		return false;
	
	return parent->HasOrInheritsMessageHandler( inMsgName, this );
}



bool	CScriptableObject::HasMessageHandler( const char* inMsgName )
{
	LEOScript*	theScript = GetScriptObject(NULL);
	if( !theScript )
		return false;
	
	LEOContextGroup*	contextGroup = GetScriptContextGroupObject();
	LEOHandlerID		handlerID = LEOContextGroupHandlerIDForHandlerName( contextGroup, inMsgName );
	if( handlerID == kLEOHandlerIDINVALID )
		return false;
	
	LEOHandler*	foundHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );
	
	return foundHandler != NULL;
}


void	CScriptableObject::SendMessage( LEOContext** outContext, std::function<void(const char*,size_t,size_t,CScriptableObject*,bool)> errorHandler, TMayGoUnhandledFlag mayGoUnhandled, const char* fmt, ... )
{
#if 0
	#define DBGLOGPAR(args...)	printf(args)
#else
	#define DBGLOGPAR(args...)	
#endif

	LEOScript*	theScript = GetScriptObject([errorHandler](const char* msg,size_t line,size_t offs,CScriptableObject* obj){ errorHandler(msg,line,offs,obj,false); });
	if( !theScript )
		return;
	LEOContextGroup*	contextGroup = GetScriptContextGroupObject();
	LEOContext*	ctx = NULL;
	bool		firstParamIsMessageName = false;
	const char*	paramStart = strchr( fmt, ' ' );
	char		msg[512] = {0};
	if( paramStart == NULL )
		paramStart = fmt +strlen(fmt);
	if( fmt[0] != 0 && fmt[0] == '%' && fmt[1] == 's' )	//
	{
		firstParamIsMessageName = true;
	}
	else
	{
		memmove( msg, fmt, paramStart -fmt );
		msg[paramStart -fmt] = '\0';
	}
	size_t		bytesNeeded = 0;
	
	//printf("Sending: %s\n",msg);
	
	CScriptableObject*			parent = GetParentObject( nullptr );
	CScriptContextUserData	*	ud = new CScriptContextUserData( parent->GetStack(), this, this );
	ctx = LEOContextCreate( contextGroup, ud, CScriptContextUserData::CleanUp );
	if( outContext )
		*outContext = ctx;
	#if REMOTE_DEBUGGER
	ctx->preInstructionProc = CScriptableObject::PreInstructionProc;
	ctx->promptProc = LEORemoteDebuggerPrompt;
	#elif COMMAND_LINE_DEBUGGER
	ctx->preInstructionProc =  LEODebuggerPreInstructionProc;
	ctx->promptProc = LEODebuggerPrompt;
	#endif
	ctx->callNonexistentHandlerProc = ScriptableObjectCallNonexistentHandler;
	
	LEOPushEmptyValueOnStack( ctx );	// Reserve space for return value.
	
	if( paramStart[0] != '\0' )	// We have params?
	{
		size_t	numParams = 0;
		// Calculate how much space we need for params temporarily:
		for( size_t x = 0; paramStart[x] != '\0'; x++ )
		{
			if( paramStart[x] != '%' )
				continue;
			x++;
			switch( paramStart[x] )
			{
				case 's':
					numParams ++;
					bytesNeeded += sizeof(const char*);
					break;

				case 'l':
					x++;
					if( paramStart[x] != 'd' )
						throw std::logic_error("Only %ld is currently supported in SendMessage format strings, no other %l...s.");
					numParams ++;
					bytesNeeded += sizeof(long);
					break;

				case 'd':
					numParams ++;
					bytesNeeded += sizeof(int);
					break;

				case 'f':
					numParams ++;
					bytesNeeded += sizeof(double);
					break;

				case 'B':
					numParams ++;
					bytesNeeded += sizeof(bool);
					break;

				default:
					throw std::logic_error("Unknown format in SendMessage format string.");
					break;
			}
		}
		
		// Grab the params in correct order into our temp buffer:
		if( bytesNeeded > 0 )
		{
			char	*	theBytes = (char*) calloc( bytesNeeded, 1 );
			char	*	currPos = theBytes;
			va_list		ap;
			va_start( ap, fmt );
				if( firstParamIsMessageName )
				{
					const char*		currMsgNameCStr = va_arg( ap, const char* );
					strlcpy( msg, currMsgNameCStr, sizeof(msg) );
				}
			
				for( size_t x = 0; paramStart[x] != '\0'; x++ )
				{
					if( paramStart[x] != '%' )
						continue;
					x++;
					switch( paramStart[x] )
					{
						case 's':
						{
							const char*		currCStr = va_arg( ap, const char* );
							DBGLOGPAR( "\"%s\"", currCStr);
							* ((const char**)currPos) = currCStr;
							currPos += sizeof(const char*);
							break;
						}

						case 'l':
						{
							x++;
							if( paramStart[x] != 'd' )
								throw std::logic_error("Only %ld is currently supported in SendMessage format strings, no other %l...s.");
							long	currLong  = va_arg( ap, long );
							DBGLOGPAR( "%ld", currLong);
							* ((long*)currPos) = currLong;
							currPos += sizeof(long);
							break;
						}

						case 'd':
						{
							int		currInt = va_arg( ap, int );
							DBGLOGPAR( "%d", currInt);
							* ((int*)currPos) = currInt;
							currPos += sizeof(int);
							break;
						}

						case 'f':
						{
							double	currDouble = va_arg( ap, double );
							DBGLOGPAR( "%f", currDouble);
							* ((double*)currPos) = currDouble;
							currPos += sizeof(double);
							break;
						}

						case 'B':
						{
							bool	currBool = va_arg( ap, int );	// bool gets promoted to int.
							DBGLOGPAR( "%s", currBool ? "true" : "false");
							* ((bool*)currPos) = currBool;
							currPos += sizeof(bool);
							break;
						}

						default:
							throw std::logic_error("Unknown format in SendMessage format string.");
							break;
					}
				}
			va_end(ap);

			// Push the params in reverse order:
			currPos = theBytes +bytesNeeded;
			for( size_t x = strlen(paramStart) -1; true; x-- )
			{
				if( x == 0 )
					break;

				if( paramStart[x] != 'l' && paramStart[x] != 's' && paramStart[x] != 'd'
					&& paramStart[x] != 'f' && paramStart[x] != 'B' )
					continue;
				char		currCh = paramStart[x];
				switch( currCh )
				{
					case 's':
					{
						currPos -= sizeof(const char*);
						const char* str = *((const char**)currPos);
						DBGLOGPAR( "pushed \"%s\"", str ? str : "(null)");
						LEOPushStringValueOnStack( ctx, str, str? strlen(str) : 0 );
						break;
					}

					case 'd':
					{
						x--;
						if( paramStart[x] == 'l' )
						{
							currPos -= sizeof(long);
							long	currLong = *((long*)currPos);
							DBGLOGPAR( "pushed %ld", currLong );
							LEOPushIntegerOnStack( ctx, currLong, kLEOUnitNone );
						}
						else
						{
							currPos -= sizeof(int);
							int	currInt = *((int*)currPos);
							DBGLOGPAR( "pushed %d", currInt );
							LEOPushIntegerOnStack( ctx, currInt, kLEOUnitNone );
						}
						break;
					}

					case 'f':
					{
						currPos -= sizeof(double);
						double	currDouble = *((double*)currPos);
						DBGLOGPAR( "pushed %f", currDouble );
						LEOPushNumberOnStack( ctx, currDouble, kLEOUnitNone );
						break;
					}

					case 'B':
					{
						currPos -= sizeof(bool);
						bool	currBool = (*((bool*)currPos)) == true;
						DBGLOGPAR( "pushed %s", currBool ? "true" : "false" );
						LEOPushBooleanOnStack( ctx, currBool );
						break;
					}

					default:
						throw std::logic_error("Unknown format in SendMessage format string.");
						break;
				}
				
				if( x == 0 )
					break;
			}

			DBGLOGPAR( @"pushed PC %zu", numParams );
			LEOPushIntegerOnStack( ctx, numParams, kLEOUnitNone );
			
			if( theBytes )
				free(theBytes);
			theBytes = NULL;
			currPos = NULL;
		}
		else
		{
			DBGLOGPAR(@"Internal error: Invalid format string in message send.");
			LEOPushIntegerOnStack( ctx, 0, kLEOUnitNone );
		}
	}
	else
	{
		if( firstParamIsMessageName )
		{
			va_list		ap;
			va_start( ap, fmt );
				const char*		currMsgNameCStr = va_arg( ap, const char* );
				strlcpy( msg, currMsgNameCStr, sizeof(msg) );
			va_end(ap);
		}
		
		LEOPushIntegerOnStack( ctx, 0, kLEOUnitNone );
	}
	
	ctx->contextCompleted = CScriptableObject::ContextCompletedProc;
	
	// Send message:
	LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( contextGroup, msg );
	if( ctx->group->messageSent )
		ctx->group->messageSent( handlerID, ctx->group );

	bool				wasHandled = false;
	LEOHandler*			theHandler = nullptr;
	CScriptableObject*	handlingObject = nullptr;
	CScriptableObject*	prevHandlingObject = nullptr;
	while( !theHandler )
	{
		prevHandlingObject = handlingObject;
		LEOValuePtr			theObjectVal = (LEOValuePtr)LEOContextGroupGetPointerForObjectIDAndSeed( ctx->group, theScript->ownerObject, theScript->ownerObjectSeed );
		if( theObjectVal )
			handlingObject = (CScriptableObject*) theObjectVal->object.object;
		
		theHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );
		if( theHandler )
		{
			LEOContextPushHandlerScriptReturnAddressAndBasePtr( ctx, theHandler, theScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
//			LEODebugPrintScript( GetScriptContextGroupObject(), theScript );
//			LEODebuggerAddBreakpoint(theHandler->instructions);
//			LEODebugPrintContext(ctx);
			LEORunInContext( theHandler->instructions, ctx );
			wasHandled = true;
			if( ctx->errMsg[0] != 0 )
				break;
//			LEODebugPrintContext(ctx);
		}
		if( !theHandler )
		{
			if( theScript->GetParentScript )
				theScript = theScript->GetParentScript( theScript, ctx, prevHandlingObject );
			if( !theScript )
			{
				if( ctx->callNonexistentHandlerProc )
				{
					ctx->callNonexistentHandlerProc( ctx, handlerID, mayGoUnhandled );
					if( ctx->errMsg[0] == 0 && mayGoUnhandled == EMayGoUnhandled )
					{
						errorHandler( nullptr, SIZE_T_MAX, SIZE_T_MAX, this, wasHandled );
					}
				}
				break;
			}
		}
	}
	if( ctx->errMsg[0] != 0 )
	{
		errorHandler( ctx->errMsg, ctx->errLine, ctx->errOffset, handlingObject ?: this, wasHandled );
	}
	
	if( !outContext )
		LEOContextRelease( ctx );
}



void	CScriptableObject::InitValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext )
{
	InitScriptableObjectValue( &outObject->object, this, keepReferences, inContext );
}


//static int	sScriptUserDatasInExistence = 0;


CScriptContextUserData::CScriptContextUserData( CStack* currStack, CScriptableObject* target, CScriptableObject* owner )
	: mCurrentStack(currStack), mTarget(target), mOwner(owner), mVisualEffectSpeed(EVisualEffectSpeedNormal)
{
	if( mCurrentStack )
		mCurrentStack->Retain();
    if( mTarget )
        mTarget->Retain();
    if( mOwner )
        mOwner->Retain();
	//sScriptUserDatasInExistence++;
}


CScriptContextUserData::~CScriptContextUserData()
{
	//sScriptUserDatasInExistence--;
	if( mCurrentStack )
		mCurrentStack->Release();
    if( mTarget )
        mTarget->Release();
    if( mOwner )
        mOwner->Release();
}


void	CScriptContextUserData::SetStack( CStack* currStack )
{
	if( currStack )
		currStack->Retain();
	if( mCurrentStack )
		mCurrentStack->Release();
	mCurrentStack = currStack;
}


void	CScriptContextUserData::SetTarget( CScriptableObject* target )
{
	if( target )
		target->Retain();
	if( mTarget )
		mTarget->Release();
	mTarget = target;
}


void	CScriptContextUserData::SetOwner( CScriptableObject* owner )
{
	if( owner )
		owner->Retain();
	if( mOwner )
		mOwner->Release();
	mOwner = owner;
}


CDocument*	CScriptContextUserData::GetDocument()
{
	if( !mCurrentStack )
		return NULL;
	return mCurrentStack->GetDocument();
}


void	CScriptContextUserData::CleanUp( void* inData )
{
	delete (CScriptContextUserData*)inData;
}


void	CScriptContextGroupUserData::CleanUp( void* inData )
{
	delete (CScriptContextGroupUserData*)inData;
}

