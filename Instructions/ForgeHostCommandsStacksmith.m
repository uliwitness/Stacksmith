//
//  ForgeHostCommandsStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "ForgeHostCommandsStacksmith.h"

size_t	kFirstStacksmithHostCommandInstruction = 0;


void	WILDGoInstruction( LEOContext* inContext )
{
	char	cardName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, cardName, sizeof(cardName), inContext );
	
	printf( "go to \"%s\"\n", cardName );	// TODO: Actually implement "go" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr		gStacksmithHostCommandInstructions[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	WILDGoInstruction
};

const char*					gStacksmithHostCommandInstructionNames[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	"WILDGoInstruction"
};

struct THostCommandEntry	gStacksmithHostCommands[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS +1] =
{
	{
		EGoIdentifier, WILD_GO_INSTRUCTION,
		{
			{ EHostParamIdentifier, EToIdentifier, EHostParameterOptional, INVALID_INSTR },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR }
		}
	}
};
