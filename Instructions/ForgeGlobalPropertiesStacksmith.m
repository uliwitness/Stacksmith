//
//  ForgeGlobalPropertiesStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "LEOGlobalProperties.h"


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


LEOInstructionFuncPtr	gGlobalPropertyInstructions[LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS] =
{
	LEOSetCursorInstruction,
	LEOPushCursorInstruction
};


const char*		gGlobalPropertyInstructionNames[LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS] =
{
	"SetCursor",
	"PushCursor"
};


extern struct TGlobalPropertyEntry	gHostGlobalProperties[(LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS / 2) +1] =
{
	{ ECursorIdentifier, SET_CURSOR_INSTR, PUSH_CURSOR_INSTR },
	{ ELastIdentifier_Sentinel, INVALID_INSTR, INVALID_INSTR }
};
