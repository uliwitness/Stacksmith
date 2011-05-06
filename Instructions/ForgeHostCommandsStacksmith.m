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
#include "WILDInputPanelController.h"
#include "LEOScript.h"


size_t	kFirstStacksmithHostCommandInstruction = 0;


void	WILDGoInstruction( LEOContext* inContext )
{
	LEOValuePtr			theValue = inContext->stackEndPtr -1;
	BOOL				canGoThere = NO;
	if( theValue->base.isa == &kLeoValueTypeWILDObject )
		canGoThere = [(id<WILDObject>)theValue->object.object goThereInNewWindow: NO];
	else
	{
		char str[1024] = { 0 };
		LEOGetValueAsString( theValue, str, sizeof(str), inContext );
		NSString	*	stackName = [NSString stringWithUTF8String: str];
		id<WILDObject>	theStack = [WILDDocument openStackNamed: stackName];
		canGoThere = [theStack goThereInNewWindow: NO];
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	if( !canGoThere )
	{
		snprintf( inContext->errMsg, sizeof(inContext->errMsg), "Can't go there." );
		inContext->keepRunning = false;
	}
	
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


void	WILDAnswerInstruction( LEOContext* inContext )
{
	char msgBuf[1024] = { 0 };
	const char*	msgStr = LEOGetValueAsString( inContext->stackEndPtr -4, msgBuf, sizeof(msgBuf), inContext );
	char btn1Buf[1024] = { 0 };
	const char*	btn1Str = LEOGetValueAsString( inContext->stackEndPtr -3, btn1Buf, sizeof(btn1Buf), inContext );
	char btn2Buf[1024] = { 0 };
	const char*	btn2Str = LEOGetValueAsString( inContext->stackEndPtr -2, btn2Buf, sizeof(btn2Buf), inContext );
	char btn3Buf[1024] = { 0 };
	const char*	btn3Str = LEOGetValueAsString( inContext->stackEndPtr -1, btn3Buf, sizeof(btn3Buf), inContext );
	
	NSInteger	returnValue = NSRunAlertPanel( [NSString stringWithCString: msgStr encoding:NSUTF8StringEncoding], @"%@", [NSString stringWithCString: btn1Str encoding:NSUTF8StringEncoding], [NSString stringWithCString: btn2Str encoding:NSUTF8StringEncoding], [NSString stringWithCString: btn3Str encoding:NSUTF8StringEncoding], @"" );
	
	const char	*hitButtonName = "OK";
	if( returnValue == NSAlertDefaultReturn )
	{
		if( strlen(btn1Str) > 0 )
			hitButtonName = btn1Str;
		else
			hitButtonName = "OK";
	}
	else if( returnValue == NSAlertAlternateReturn )
		hitButtonName = btn2Str;
	else if( returnValue == NSAlertOtherReturn )
		hitButtonName = btn3Str;
	
	LEOHandler	*	theHandler = LEOContextPeekCurrentHandler( inContext );
	long			bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "result" );
	if( bpRelativeOffset >= 0 )
	{
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, hitButtonName, inContext );
	}

	bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "it" );
	if( bpRelativeOffset >= 0 )
	{
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, hitButtonName, inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -4 );
	
	inContext->currentInstruction++;
}


void	WILDAskInstruction( LEOContext* inContext )
{
	char msgBuf[1024] = { 0 };
	const char*	msgStr = LEOGetValueAsString( inContext->stackEndPtr -2, msgBuf, sizeof(msgBuf), inContext );
	char answerBuf[1024] = { 0 };
	const char*	answerStr = LEOGetValueAsString( inContext->stackEndPtr -1, answerBuf, sizeof(answerBuf), inContext );
	
	WILDInputPanelController	*	inputPanel = [WILDInputPanelController inputPanelWithPrompt: [NSString stringWithUTF8String: msgStr] answer: [NSString stringWithUTF8String: answerStr]];
	NSInteger						returnValue = [inputPanel runModal];
	
	LEOHandler	*	theHandler = LEOContextPeekCurrentHandler( inContext );
	long			bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "result" );
	if( bpRelativeOffset >= 0 )
	{
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, ((returnValue == NSAlertDefaultReturn) ? "OK" : "Cancel"), inContext );
	}

	bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "it" );
	if( bpRelativeOffset >= 0 )
	{
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, [[inputPanel answerString] UTF8String], inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr		gStacksmithHostCommandInstructions[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	WILDGoInstruction,
	WILDVisualEffectInstruction,
	WILDAnswerInstruction,
	WILDAskInstruction
};

const char*					gStacksmithHostCommandInstructionNames[WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS] =
{
	"WILDGoInstruction",
	"WILDVisualEffectInstruction",
	"WILDAnswerInstruction",
	"WILDAskInstruction"
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
		EAnswerIdentifier, WILD_ANSWER_INSTR, 0, 0,
		{
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParamLabeledValue, EWithIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParamLabeledValue, EOrIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParamLabeledValue, EOrIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0 }
		}
	},
	{
		EAskIdentifier, WILD_ASK_INSTR, 0, 0,
		{
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0 },
			{ EHostParamLabeledValue, EWithIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0 },
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
