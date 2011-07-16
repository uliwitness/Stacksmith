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
#import "LEOScript.h"


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
	WILDBackground	*	theBackground = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				backgroundName[1024] = { 0 };
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		if( theNumber > 0 && theNumber <= [[frontStack backgrounds] count] )
			theBackground = [[frontStack cards] objectAtIndex: theNumber -1];
		else
			snprintf( backgroundName, sizeof(backgroundName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, backgroundName, sizeof(backgroundName), inContext );
		
		theBackground = [frontStack backgroundNamed: [NSString stringWithUTF8String: backgroundName]];
	}
	
	if( theBackground )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, theBackground, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find background \"%s\".", backgroundName );
		inContext->keepRunning = false;
	}
	
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
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"field"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"field"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find field \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDCardButtonInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"button"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"button"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find button \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDCardMoviePlayerInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"moviePlayer"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"moviePlayer"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find movie player \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDCardPartInstruction( LEOContext* inContext )
{
	WILDPart	*	thePart = nil;
	WILDStack	*	frontStack = [WILDDocument frontStackNamed: nil];
	char			partName[1024] = { 0 };
	WILDCard	*	theCard = [frontStack currentCard];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: nil];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: nil];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find part \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundFieldInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"field"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"field"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find field \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundButtonInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"button"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"button"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find button \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundMoviePlayerInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: @"moviePlayer"];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: @"moviePlayer"];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find movie player \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDBackgroundPartInstruction( LEOContext* inContext )
{
	WILDPart		*	thePart = nil;
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	char				partName[1024] = { 0 };
	WILDBackground	*	theCard = [[frontStack currentCard] owningBackground];
	
	if( LEOCanGetAsNumber( inContext->stackEndPtr -1, inContext ) )
	{
		LEOInteger	theNumber = LEOGetValueAsInteger( inContext->stackEndPtr -1, inContext );
		thePart = [theCard partAtIndex: theNumber -1 ofType: nil];
		
		if( !thePart )
			snprintf( partName, sizeof(partName), "%lld", theNumber );
	}
	else
	{
		LEOGetValueAsString( inContext->stackEndPtr -1, partName, sizeof(partName), inContext );
		
		thePart = [theCard partNamed: [NSString stringWithUTF8String: partName] ofType: nil];
	}
	
	if( thePart )
	{
		LEOCleanUpValue( inContext->stackEndPtr -1, kLEOInvalidateReferences, inContext );
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, thePart, kLEOInvalidateReferences, inContext );
	}
	else
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't find part \"%s\".", partName );
		inContext->keepRunning = false;
	}
	
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


void	WILDThisStackInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
		
	if( frontStack )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, frontStack, kLEOInvalidateReferences, inContext );
	}
	else
	{
		strncpy( inContext->errMsg, "No stack open at the moment.", sizeof(inContext->errMsg) );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDThisBackgroundInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDBackground	*	theBackground = [[frontStack currentCard] owningBackground];
	
	if( theBackground )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, theBackground, kLEOInvalidateReferences, inContext );
	}
	else
	{
		strncpy( inContext->errMsg, "No stack open at the moment.", sizeof(inContext->errMsg) );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


void	WILDThisCardInstruction( LEOContext* inContext )
{
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard		*	theCard = [frontStack currentCard];
	
	if( theCard )
	{
		inContext->stackEndPtr++;
		LEOInitWILDObjectValue( inContext->stackEndPtr -1, theCard, kLEOInvalidateReferences, inContext );
	}
	else
	{
		strncpy( inContext->errMsg, "No stack open at the moment.", sizeof(inContext->errMsg) );
		inContext->keepRunning = false;
	}
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr		gStacksmithHostFunctionInstructions[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS] =
{
	WILDStackInstruction,
	WILDBackgroundInstruction,
	WILDCardInstruction,
	WILDCardFieldInstruction,
	WILDCardButtonInstruction,
	WILDCardMoviePlayerInstruction,
	WILDCardPartInstruction,
	WILDBackgroundFieldInstruction,
	WILDBackgroundButtonInstruction,
	WILDBackgroundMoviePlayerInstruction,
	WILDBackgroundPartInstruction,
	WILDNextCardInstruction,
	WILDPreviousCardInstruction,
	WILDFirstCardInstruction,
	WILDLastCardInstruction,
	WILDThisStackInstruction,
	WILDThisBackgroundInstruction,
	WILDThisCardInstruction
};

const char*					gStacksmithHostFunctionInstructionNames[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS] =
{
	"WILDStackInstruction",
	"WILDBackgroundInstruction",
	"WILDCardInstruction",
	"WILDCardFieldInstruction",
	"WILDCardButtonInstruction",
	"WILDCardMoviePlayerInstruction",
	"WILDCardPartInstruction",
	"WILDBackgroundFieldInstruction",
	"WILDBackgroundButtonInstruction",
	"WILDBackgroundMoviePlayerInstruction",
	"WILDBackgroundPartInstruction",
	"WILDNextCardInstruction",
	"WILDPreviousCardInstruction",
	"WILDFirstCardInstruction",
	"WILDLastCardInstruction",
	"WILDThisStackInstruction",
	"WILDThisBackgroundInstruction",
	"WILDThisCardInstruction"
};

struct THostCommandEntry	gStacksmithHostFunctions[WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS +1] =
{
	{
		EStackIdentifier, WILD_STACK_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EBackgroundIdentifier, WILD_BACKGROUND_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_BACKGROUND_BUTTON_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_BACKGROUND_FIELD_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_BACKGROUND_PART_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterOptional, WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
		}
	},
	{
		ECardIdentifier, WILD_CARD_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_CARD_BUTTON_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_CARD_FIELD_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterOptional, WILD_CARD_PART_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterOptional, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0 },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
		}
	},
	{
		EButtonIdentifier, WILD_CARD_FIELD_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EButtonIdentifier, WILD_CARD_BUTTON_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EMovieIdentifier, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0,
		{
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0 },
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
		EPartIdentifier, WILD_CARD_PART_INSTRUCTION, 0, 0,
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		ENextIdentifier, INVALID_INSTR2, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_NEXT_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EPreviousIdentifier, INVALID_INSTR2, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_PREVIOUS_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EFirstIdentifier, INVALID_INSTR2, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_FIRST_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		ELastIdentifier, INVALID_INSTR2, 0, 0,
		{
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_LAST_CARD_INSTRUCTION, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
		EThisIdentifier, INVALID_INSTR2, 0, 0,
		{
			{ EHostParamIdentifier, EStackIdentifier, EHostParameterOptional, WILD_THIS_STACK_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_THIS_BACKGROUND_INSTRUCTION, 0, 0 },
			{ EHostParamIdentifier, ECardIdentifier, EHostParameterOptional, WILD_THIS_CARD_INSTRUCTION, 0, 0 },
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
