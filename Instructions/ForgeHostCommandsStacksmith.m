//
//  ForgeHostCommandsStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "ForgeHostCommandsStacksmith.h"
#include "ForgeWILDObjectValue.h"
#include "WILDDocument.h"


size_t	kFirstStacksmithHostCommandInstruction = 0;


void	WILDGoInstruction( LEOContext* inContext )
{
	LEOValuePtr			theValue = inContext->stackEndPtr -1;
	if( theValue->base.isa == &kLeoValueTypeWILDObject )
		[(id<WILDObject>)theValue->object.object goThereInNewWindow: NO];
	else
	{
		char str[1024] = { 0 };
		LEOGetValueAsString( theValue, str, sizeof(str), inContext );
		NSString	*	stackName = [NSString stringWithUTF8String: str];
		id<WILDObject>	theStack = [WILDDocument openStackNamed: stackName];
		[theStack goThereInNewWindow: NO];
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


void	WILDVisualEffectInstruction( LEOContext* inContext )
{
	char str[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, str, sizeof(str), inContext );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	// TODO: Actually store the effect somewhere.
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr		gStacksmithHostCommandInstructions[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	WILDGoInstruction,
	WILDVisualEffectInstruction
};

const char*					gStacksmithHostCommandInstructionNames[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	"WILDGoInstruction",
	"WILDVisualEffectInstruction"
};

struct THostCommandEntry	gStacksmithHostCommands[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS +1] =
{
	{
		EGoIdentifier, WILD_GO_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EToIdentifier, EHostParameterOptional, WILD_GO_INSTRUCTION, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 }
		}
	},
	{
		EVisualIdentifier, WILD_VISUAL_EFFECT_INSTR, 0, 0,
		{
			{ EHostParamIdentifier, EEffectIdentifier, EHostParameterOptional, WILD_VISUAL_EFFECT_INSTR, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 }
		}
	}
};
