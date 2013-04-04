//
//  ForgeGlobalPropertiesStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "LEOGlobalProperties.h"
#include "StacksmithVersion.h"
#include <string.h>


#define TOSTRING2(x)	#x
#define TOSTRING(x)		TOSTRING2(x)


void	LEOSetCursorInstruction( LEOContext* inContext );
void	LEOPushCursorInstruction( LEOContext* inContext );
void	LEOSetVersionInstruction( LEOContext* inContext );
void	LEOPushVersionInstruction( LEOContext* inContext );



void	LEOSetCursorInstruction( LEOContext* inContext )
{
	char		propValueStr[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, propValueStr, sizeof(propValueStr), inContext );
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	// TODO: Set the cursor with propValueStr here.
	
	inContext->currentInstruction++;
}


void	LEOPushCursorInstruction( LEOContext* inContext )
{
	LEOPushIntegerOnStack( inContext, 128 );	// TODO: Actually retrieve actual cursor ID here.
	
	inContext->currentInstruction++;
}


void	LEOSetVersionInstruction( LEOContext* inContext )
{
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	LEOContextStopWithError( inContext, "You can't change the version number." );
	
	inContext->currentInstruction++;
}


void	LEOPushVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = TOSTRING(STACKSMITH_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


LEOINSTR_START(GlobalProperty,LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOSetCursorInstruction)
LEOINSTR(LEOPushCursorInstruction)
LEOINSTR(LEOSetVersionInstruction)
LEOINSTR_LAST(LEOPushVersionInstruction)


struct TGlobalPropertyEntry	gHostGlobalProperties[(LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS / 2) +1] =
{
	{ ECursorIdentifier, SET_CURSOR_INSTR, PUSH_CURSOR_INSTR },
	{ EVersionIdentifier, SET_VERSION_INSTR, PUSH_VERSION_INSTR },
	{ ELastIdentifier_Sentinel, INVALID_INSTR, INVALID_INSTR }
};
