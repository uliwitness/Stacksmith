/*
 *  WILDPropertyInstructions.m
 *  Leonie
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

/*!
	@header WILDPropertyInstructions
	While Forge knows how to parse property expressions, it does not know about
	the host-specific objects and how to ask them for their properties. So it
	assumes that the instructions for that will be defined by the host as defined
	by the constants and global declarations in "LEOPropertyInstructions.h". To
	register these properties at startup, call:
	<pre>
	LEOAddInstructionsToInstructionArray( gPropertyInstructions, LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS, &kFirstPropertyInstruction );
	</pre>
	Forge will then use kFirstPropertyInstruction to offset all the instruction
	IDs as needed when generating code for a property expression.
*/

#import "Forge.h"
#import "CScriptableObjectValue.h"


void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOPushMeInstruction( LEOContext* inContext );
void	LEOHasPropertyInstruction( LEOContext* inContext );
void	LEOIHavePropertyInstruction( LEOContext* inContext );


using namespace Carlson;


/*!
	Push the value of a property of an object onto the stack, ready for use e.g.
	in an expression. Two parameters need to be pushed on the stack before
	calling this and will be popped off the stack by this instruction before
	the property value is pushed:
	
	propertyName -	The name of the property to retrieve, as a string or some
					value that converts to a string.
	
	object -		The object from which to retrieve the property, as a
					WILDObjectValue (i.e. isa = kLeoValueTypeWILDObject).
	
	(PUSH_PROPERTY_OF_OBJECT_INSTR)
*/
void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -2;
	LEOValuePtr		theObject = inContext->stackEndPtr -1;
	
	char			propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr		objectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		if( !((CScriptableObject*)objectValue->object.object)->GetPropertyNamed( propNameStr, 0, 0, inContext, thePropertyName ) )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Object does not have property \"%s\".", propNameStr );
			return;
		}
	}
	else
	{
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		LEOValuePtr	theValue = LEOGetValueForKey( theObject, propNameStr, thePropertyName, kLEOInvalidateReferences, inContext );
		if( !theValue )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Can't get property \"%s\" of this.", propNameStr );
			return;
		}
		else if( theValue == thePropertyName )	// This makes "rectangle of screen 1" not complain because the dictionary went away.
			LEOInitSimpleCopy( theValue, thePropertyName, kLEOInvalidateReferences, inContext );
//		else if( theValue != thePropertyName )	// What was this for?
//			LEOInitCopy( theValue, thePropertyName, kLEOInvalidateReferences, inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
	Change the value of a particular property of an object. Three parameters must
	have been pushed on the stack before this instruction is called, and will be
	popped off the stack:
	
	propertyName -	The name of the property to change, as a string value or value
					that converts to a string.
					
	object -		The object to change the property on. This must be a
					WILDObjectValue (i.e. isa = kLeoValueTypeWILDObject).
	
	value -			The new value to assign to the given property.
	
	(SET_PROPERTY_OF_OBJECT_INSTR)
*/
void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		theValue = inContext->stackEndPtr -1;
	LEOValuePtr		theObject = inContext->stackEndPtr -2;
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -3;
	
	char		propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr	theObjectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeScriptableObject, inContext );
	
	if( theObjectValue )
	{
		CScriptableObject*	theScriptObject = (CScriptableObject*)theObjectValue->object.object;
		if( !theScriptObject->SetValueForPropertyNamed( theValue, inContext, propNameStr, 0, 0 ) )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Object does not have property \"%s\".", propNameStr );
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


/*!
	This instruction pushes a reference to the object owning the current script
	onto the stack. It implements the 'me' object specifier for Hammer.
	
	(PUSH_ME_INSTR)
*/

void	LEOPushMeInstruction( LEOContext* inContext )
{
	LEOScript	*	myScript = LEOContextPeekCurrentScript( inContext );
	
	inContext->stackEndPtr++;
	
	LEOInitReferenceValueWithIDs( inContext->stackEndPtr -1, myScript->ownerObject, myScript->ownerObjectSeed,
									  kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


/*!
	This instruction pushes a boolean that indicates whether the given object
	has the given property.
	
	(HAS_PROPERTY_INSTR)
*/

void	LEOHasPropertyInstruction( LEOContext* inContext )
{
	LEOValuePtr			theValue = inContext->stackEndPtr -1;
	LEOValuePtr			meValue = LEOFollowReferencesAndReturnValueOfType( inContext->stackEndPtr -2, &kLeoValueTypeScriptableObject, inContext );
	if( !meValue )
	{
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Can't find target object." );
		return;
	}
	char				buf[200] = {};
	const char*			propName = LEOGetValueAsString( theValue, buf, sizeof(buf), inContext );
	LEOValue			propValue = {};
	CScriptableObject*	me = (CScriptableObject*)meValue->object.object;
	
	bool	hasProp = me->GetPropertyNamed( propName, 0, 0, inContext, &propValue );
	if( hasProp )
		LEOCleanUpValue( &propValue, kLEOInvalidateReferences, inContext );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
	LEOInitBooleanValue( inContext->stackEndPtr -1, hasProp, kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


/*
	This instruction pushes a boolean that indicates whether the object
	owning the script has the given property.
 
	(I_HAVE_PROPERTY_INSTRUCTION)
*/

void	LEOIHavePropertyInstruction( LEOContext* inContext )
{
	LEODebugPrintContext( inContext );
	
	LEOScript		*	myScript = LEOContextPeekCurrentScript( inContext );
	LEOValuePtr			meValue = (LEOValuePtr) LEOContextGroupGetPointerForObjectIDAndSeed( inContext->group, myScript->ownerObject, myScript->ownerObjectSeed );
	CScriptableObject*	me = (CScriptableObject*)meValue->object.object;
	
	LEOValuePtr		theValue = inContext->stackEndPtr -1;
	char			buf[200] = {};
	const char*	propName = LEOGetValueAsString( theValue, buf, sizeof(buf), inContext );
	LEOValue		propValue = {};
	
	bool			hasProp = me->GetPropertyNamed( propName, 0, 0, inContext, &propValue );
	if( hasProp )
		LEOCleanUpValue( &propValue, kLEOInvalidateReferences, inContext );
	
	LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
	LEOInitBooleanValue( inContext->stackEndPtr -1, hasProp, kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


LEOINSTR_START(Property,LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOPushPropertyOfObjectInstruction)
LEOINSTR(LEOSetPropertyOfObjectInstruction)
LEOINSTR(LEOPushMeInstruction)
LEOINSTR(LEOHasPropertyInstruction)
LEOINSTR_LAST(LEOIHavePropertyInstruction)


