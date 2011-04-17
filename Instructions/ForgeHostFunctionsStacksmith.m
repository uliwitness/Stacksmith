//
//  ForgeHostFunctionsStacksmith.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "ForgeHostFunctionsStacksmith.h"
#include "ForgeWILDObjectValue.h"
#import "WILDDocument.h"
#import "WILDStack.h"


size_t	kFirstStacksmithHostFunctionInstruction = 0;


void	WILDStackInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	NSString	*	stackNameObj = [NSString stringWithUTF8String: stackName];
	WILDStack	*	theStack = nil;
	WILDDocument*	frontDoc = nil;
	NSArray*		docs = [[NSDocumentController sharedDocumentController] documents];
	for( WILDDocument* currDoc in docs )
	{
		if( [currDoc isKindOfClass: [WILDDocument class]] )
		{
			frontDoc = currDoc;
			theStack = [frontDoc stackNamed: stackNameObj];
			if( theStack )
				break;
		}
	}
	
	BOOL	reportError = YES;
	
	if( !theStack )
	{
		if( [[NSApp delegate] openStandardStackNamed: stackNameObj] )
			reportError = NO;
	}
	
	if( theStack )
	{
		LEOValuePtr	valueToReplace = inContext->stackEndPtr -1;
		LEOCleanUpValue( valueToReplace, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( valueToReplace, theStack, kLEOInvalidateReferences, inContext );
	}
	else if( reportError )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find stack \"%s\".", stackName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "background \"%s\"\n", stackName );	// TODO: Actually implement "background" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDCardInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "card \"%s\"\n", stackName );	// TODO: Actually implement "card" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDCardFieldInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "card field \"%s\"\n", stackName );	// TODO: Actually implement "field" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDCardButtonInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "card button \"%s\"\n", stackName );	// TODO: Actually implement "button" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDCardPartInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "card part \"%s\"\n", stackName );	// TODO: Actually implement "part" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDBackgroundFieldInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "background field \"%s\"\n", stackName );	// TODO: Actually implement "field" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDBackgroundButtonInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "background button \"%s\"\n", stackName );	// TODO: Actually implement "button" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


void	WILDBackgroundPartInstruction( LEOContext* inContext )
{
	char	stackName[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, stackName, sizeof(stackName), inContext );
	
	printf( "background part \"%s\"\n", stackName );	// TODO: Actually implement "part" command here.
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	LEOPushEmptyValueOnStack( inContext );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr		gStacksmithHostFunctionInstructions[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS] =
{
	WILDStackInstruction,
	WILDBackgroundInstruction,
	WILDCardInstruction,
	WILDCardFieldInstruction,
	WILDCardButtonInstruction,
	WILDCardPartInstruction,
	WILDBackgroundFieldInstruction,
	WILDBackgroundButtonInstruction,
	WILDBackgroundPartInstruction
};

const char*					gStacksmithHostFunctionInstructionNames[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS] =
{
	"WILDStackInstruction",
	"WILDBackgroundInstruction",
	"WILDCardInstruction",
	"WILDCardFieldInstruction",
	"WILDCardButtonInstruction",
	"WILDCardPartInstruction",
	"WILDBackgroundFieldInstruction",
	"WILDBackgroundButtonInstruction",
	"WILDBackgroundPartInstruction"
};

struct THostCommandEntry	gStacksmithHostFunctions[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS +1] =
{
	{
		EStackIdentifier, WILD_STACK_INSTRUCTION,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
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
		EBackgroundIdentifier, WILD_BACKGROUND_INSTRUCTION,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_BACKGROUND_BUTTON_INSTRUCTION },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_BACKGROUND_FIELD_INSTRUCTION },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_BACKGROUND_PART_INSTRUCTION },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
		}
	},
	{
		ECardIdentifier, WILD_CARD_INSTRUCTION,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_CARD_BUTTON_INSTRUCTION },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_CARD_FIELD_INSTRUCTION },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_CARD_PART_INSTRUCTION },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
		}
	},
	{
		EButtonIdentifier, WILD_CARD_FIELD_INSTRUCTION,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
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
		EButtonIdentifier, WILD_CARD_BUTTON_INSTRUCTION,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
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
		EPartIdentifier, WILD_CARD_PART_INSTRUCTION,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR },
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
