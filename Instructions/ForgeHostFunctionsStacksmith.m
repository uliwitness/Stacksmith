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
	WILDStack	*	theStack = [WILDDocument openStackNamed: stackNameObj];
		
	if( theStack )
	{
		LEOValuePtr	valueToReplace = inContext->stackEndPtr -1;
		LEOCleanUpValue( valueToReplace, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( valueToReplace, theStack, kLEOInvalidateReferences, inContext );
	}
	else
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
	WILDCard	*	theCard = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			cardName[1024] = { 0 };
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		if( theNumber > 0 && theNumber <= [[frontStack cards] count] )
			theCard = [[frontStack cards] objectAtIndex: theNumber -1];
		else
			snprintf( cardName, sizeof(cardName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, cardName, sizeof(cardName), inContext );
		
		theCard = [frontStack cardNamed: [NSString stringWithUTF8String: cardName]];
	}
	
	if( theCard )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, theCard, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find card \"%s\".", cardName );
		inContext->keepRunning = false;
	}
	
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


void	WILDNextCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack document] currentCard];
	NSUInteger		cardIdx = [[theStack cards] indexOfObject: theCard];
	cardIdx++;
	if( cardIdx >= [[theStack cards] count] )
		cardIdx = 0;
	theCard = [[theStack cards] objectAtIndex: cardIdx];
	
	LEOInitWILDObjectValue( inContext->stackEndPtr, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDPreviousCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack document] currentCard];
	NSUInteger		cardIdx = [[theStack cards] indexOfObject: theCard];
	if( cardIdx == 0 )
		cardIdx = [[theStack cards] count] -1;
	else
		cardIdx--;
	theCard = [[theStack cards] objectAtIndex: cardIdx];
	
	LEOInitWILDObjectValue( inContext->stackEndPtr, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDFirstCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack cards] objectAtIndex: 0];
	
	LEOInitWILDObjectValue( inContext->stackEndPtr, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
	inContext->currentInstruction++;
}


void	WILDLastCardInstruction( LEOContext* inContext )
{
	WILDStack	*	theStack = [WILDDocument frontStackNamed: nil];
	WILDCard	*	theCard = [[theStack cards] lastObject];
	
	LEOInitWILDObjectValue( inContext->stackEndPtr, theCard, kLEOInvalidateReferences, inContext );
	inContext->stackEndPtr ++;
	
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
	WILDBackgroundPartInstruction,
	WILDNextCardInstruction,
	WILDPreviousCardInstruction,
	WILDFirstCardInstruction,
	WILDLastCardInstruction
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
	"WILDBackgroundPartInstruction",
	"WILDNextCardInstruction",
	"WILDPreviousCardInstruction",
	"WILDFirstCardInstruction",
	"WILDLastCardInstruction"
};

struct THostCommandEntry	gStacksmithHostFunctions[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS +1] =
{
	{
		EStackIdentifier, WILD_STACK_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_BACKGROUND_BUTTON_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_BACKGROUND_FIELD_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_BACKGROUND_PART_INSTRUCTION, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
		}
	},
	{
		ECardIdentifier, WILD_CARD_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_CARD_BUTTON_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_CARD_FIELD_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_CARD_PART_INSTRUCTION, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
		}
	},
	{
		EButtonIdentifier, WILD_CARD_FIELD_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		EButtonIdentifier, WILD_CARD_BUTTON_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		EPartIdentifier, WILD_CARD_PART_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ENextIdentifier, INVALID_INSTR, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_NEXT_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		EPreviousIdentifier, INVALID_INSTR, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_PREVIOUS_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_FIRST_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ELastIdentifier, INVALID_INSTR, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_LAST_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR, 0, 0,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR, 0, 0,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR, 0, 0,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR, 0, 0,
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR, 0, 0 }
		}
	}
};
