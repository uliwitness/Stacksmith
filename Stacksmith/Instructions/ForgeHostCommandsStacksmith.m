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
#include "WILDStack.h"
#include "WILDCard.h"
#include "WILDInputPanelController.h"
#include "LEOScript.h"
#include "LEORemoteDebugger.h"
#import "WILDMessageBox.h"
#import "ULIMelodyQueue.h"


void	WILDGoInstruction( LEOContext* inContext );
void	WILDVisualEffectInstruction( LEOContext* inContext );
void	WILDAnswerInstruction( LEOContext* inContext );
void	WILDAskInstruction( LEOContext* inContext );
void	WILDCreateInstruction( LEOContext* inContext );
void	WILDDeleteInstruction( LEOContext* inContext );
void	WILDDebugCheckpointInstruction( LEOContext* inContext );
void	WILDCreateUserPropertyInstruction( LEOContext* inContext );
void	WILDPrintInstruction( LEOContext* inContext );
void	WILDPlayMelodyInstruction( LEOContext* inContext );


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
		WILDStack*	theStack = [WILDDocument openStackNamed: stackName];
		canGoThere = [theStack goThereInNewWindow: NO];
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	if( !canGoThere )
	{
		LEOContextStopWithError( inContext, "Can't go there." );
	}
	
	WILDStack			*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard			*	currentCard = [frontStack currentCard];
	[currentCard setTransitionType: nil subtype: nil];

	inContext->currentInstruction++;
}


void	WILDVisualEffectInstruction( LEOContext* inContext )
{
	char str[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, str, sizeof(str), inContext );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	WILDStack			*	frontStack = [WILDDocument frontStackNamed: nil];
	WILDCard			*	currentCard = [frontStack currentCard];
	static NSDictionary *	sTransitions = nil;
	
	if( !sTransitions )
	{
		sTransitions = [[NSDictionary alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"TransitionMappings" ofType: @"plist"]];
	}
	
	NSDictionary * currTransition = [sTransitions objectForKey: [NSString stringWithUTF8String: str]];
	
	[currentCard setTransitionType: [currTransition objectForKey: @"CATransitionType"] subtype: [currTransition objectForKey: @"CATransitionSubtype"]];
	
	inContext->currentInstruction++;
}


void	WILDAnswerInstruction( LEOContext* inContext )
{
	char msgBuf[1024] = { 0 };
	const char*	msgStr = LEOGetValueAsString( inContext->stackEndPtr -4, msgBuf, sizeof(msgBuf), inContext );
	if( !inContext->keepRunning )
		return;
	char btn1Buf[1024] = { 0 };
	const char*	btn1Str = LEOGetValueAsString( inContext->stackEndPtr -3, btn1Buf, sizeof(btn1Buf), inContext );
	if( !inContext->keepRunning )
		return;
	char btn2Buf[1024] = { 0 };
	const char*	btn2Str = LEOGetValueAsString( inContext->stackEndPtr -2, btn2Buf, sizeof(btn2Buf), inContext );
	if( !inContext->keepRunning )
		return;
	char btn3Buf[1024] = { 0 };
	const char*	btn3Str = LEOGetValueAsString( inContext->stackEndPtr -1, btn3Buf, sizeof(btn3Buf), inContext );
	if( !inContext->keepRunning )
		return;
	
	NSInteger	returnValue = 0;
	@try
	{
		returnValue = NSRunAlertPanel( [NSString stringWithCString: msgStr encoding:NSUTF8StringEncoding], @"%@", [NSString stringWithCString: btn1Str encoding:NSUTF8StringEncoding], [NSString stringWithCString: btn2Str encoding:NSUTF8StringEncoding], [NSString stringWithCString: btn3Str encoding:NSUTF8StringEncoding], @"" );
	}
	@catch( NSException * err )
	{
		
	}
	
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
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, hitButtonName, strlen(hitButtonName), inContext );	// TODO: Make NUL-safe.
	}

	bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "it" );
	if( bpRelativeOffset >= 0 )
	{
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, hitButtonName, strlen(hitButtonName), inContext );	// TODO: Make NUL-safe.
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
		const char*		theBtn = ((returnValue == NSAlertDefaultReturn) ? "OK" : "Cancel");
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, theBtn, strlen(theBtn), inContext );
	}

	bpRelativeOffset = LEOHandlerFindVariableByName( theHandler, "it" );
	if( bpRelativeOffset >= 0 )
	{
		NSString	*	answerString = [inputPanel answerString];
		LEOSetValueAsString( inContext->stackBasePtr +bpRelativeOffset, [answerString UTF8String], [answerString lengthOfBytesUsingEncoding: NSUTF8StringEncoding], inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


void	WILDCreateInstruction( LEOContext* inContext )
{
	//LEODebugPrintContext( inContext );
	
	char typeNameBuf[1024] = { 0 };
	const char*	typeNameStr = LEOGetValueAsString( inContext->stackEndPtr -2, typeNameBuf, sizeof(typeNameBuf), inContext );
	char nameBuf[1024] = { 0 };
	const char* nameStr = LEOGetValueAsString( inContext->stackEndPtr -1, nameBuf, sizeof(nameBuf), inContext );
	
	SEL				newObjectAction = Nil;
	NSString	*	newTitle = [NSString stringWithUTF8String: nameStr];
	if( strcasecmp(typeNameStr, "button") == 0 )
		newObjectAction = @selector(createNewButtonNamed:);
	else if( strcasecmp(typeNameStr, "field") == 0 )
		newObjectAction = @selector(createNewFieldNamed:);
	else if( strcasecmp(typeNameStr, "player") == 0 )
		newObjectAction = @selector(createNewMoviePlayerNamed:);
	else if( strcasecmp(typeNameStr, "browser") == 0 )
		newObjectAction = @selector(createNewBrowserNamed:);
	else
		LEOContextStopWithError( inContext, "Don't know how to create a \"%s\".", typeNameStr );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	if( newObjectAction != Nil )
	{
		WILDStack			*	frontStack = [WILDDocument frontStackNamed: nil];
		WILDCard			*	currentCard = [frontStack currentCard];
		[currentCard performSelector: newObjectAction withObject: newTitle];
	}
	
	inContext->currentInstruction++;
}


void	WILDDebugCheckpointInstruction( LEOContext* inContext )
{
	LEOInstruction	*	instr = inContext->currentInstruction;
	
	LEORemoteDebuggerAddBreakpoint( instr );			// Ensure debugger knows to stop here.
	LEORemoteDebuggerPreInstructionProc( inContext );	// Trigger debugger.
	LEORemoteDebuggerRemoveBreakpoint( instr );			// Clean up after debugger.
	
	inContext->currentInstruction++;
}


void	WILDCreateUserPropertyInstruction( LEOContext* inContext )
{
	//LEODebugPrintContext( inContext );

	char propNameBuf[1024] = { 0 };
	const char*	propNameStr = LEOGetValueAsString( inContext->stackEndPtr -2, propNameBuf, sizeof(propNameBuf), inContext );
	LEOValuePtr objValue = inContext->stackEndPtr -1;
	if( objValue->base.isa == &kLeoValueTypeWILDObject )
	{
		id<WILDObject>	theObject = (id<WILDObject>) objValue->object.object;
		if( [theObject respondsToSelector: @selector(addUserPropertyNamed:)] )
			[theObject addUserPropertyNamed: [[NSString stringWithUTF8String: propNameStr] lowercaseString]];
	}
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


/*!
	Pop a value off the back of the stack (or just read it from the given
	BasePointer-relative address) and present it to the user in string form.
	(WILD_PRINT_INSTR)
	
	param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
				off the stack. Otherwise, this is a basePtr-relative address
				where a value will just be read.
*/

void	WILDPrintInstruction( LEOContext* inContext )
{
	char			buf[1024] = { 0 };
	
	bool			popOffStack = (inContext->currentInstruction->param1 == BACK_OF_STACK);
	union LEOValue*	theValue = popOffStack ? (inContext->stackEndPtr -1) : (inContext->stackBasePtr +inContext->currentInstruction->param1);
	if( theValue == NULL || theValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid value." );
		return;
	}
	LEOGetValueAsString( theValue, buf, sizeof(buf), inContext );
	
	NSString	*	objcString = [NSString stringWithCString: buf encoding: NSUTF8StringEncoding];
	[[WILDMessageBox sharedMessageBox] setStringValue: objcString];
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and delete it. If it's an object, we remove it
 from its owner, if it is a chunk, we empty it and any delimiters.
 (WILD_DELETE_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDDeleteInstruction( LEOContext* inContext )
{
	bool			popOffStack = (inContext->currentInstruction->param1 == BACK_OF_STACK);
	union LEOValue*	theValue = popOffStack ? (inContext->stackEndPtr -1) : (inContext->stackBasePtr +inContext->currentInstruction->param1);
	if( theValue == NULL || theValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid value." );
		return;
	}
	
	if( theValue->base.isa == &kLeoValueTypeWILDObject )
	{
		BOOL	couldDelete = false;
		if( [(id<WILDObject>)theValue->object.object respondsToSelector: @selector(deleteWILDObject)] )
			couldDelete = [(id<WILDObject>)theValue->object.object deleteWILDObject];
		if( !couldDelete )
			LEOContextStopWithError( inContext, "Unable to delete this object." );
	}
	else
		LEOSetValueAsString( theValue, NULL, 0, inContext );
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Take the name of an instrument off the back of the stack and look up the
 corresponding sound file up the hierarchy and finally in the system. Also take
 a melody string off the back of the stack and hand both of them off to
 ULIMelodyQueue to play that melody using that instrument. Implements the 'play'
 command.
 (WILD_PLAY_MELODY_INSTR)
 */

void	WILDPlayMelodyInstruction( LEOContext* inContext )
{
	//LEODebugPrintContext( inContext );
	
	WILDStack		*	frontStack = [WILDDocument frontStackNamed: nil];

	LEOValuePtr	theInstrument = inContext->stackEndPtr -2;
	LEOValuePtr	theMelody = inContext->stackEndPtr -1;
	
	char		instrNameStrBuf[256] = {};
	const char*	instrNameStr = LEOGetValueAsString( theInstrument, instrNameStrBuf, sizeof(instrNameStrBuf), inContext );
	if( !inContext->keepRunning )
		return;
	char		melodyStrBuf[256] = {};
	const char*	melodyStr = LEOGetValueAsString( theMelody, melodyStrBuf, sizeof(melodyStrBuf), inContext );
	if( !inContext->keepRunning )
		return;
	
	NSString		*	resourceName = [NSString stringWithUTF8String: instrNameStr];
	NSURL			*	theURL = [frontStack.document URLForMediaOfType: @"sound" name: resourceName];
	if( !theURL )
	{
		NSString	*	thePath = [[NSBundle mainBundle] pathForSoundResource: resourceName];
		if( thePath )
			theURL = [NSURL fileURLWithPath: thePath];
	}
	if( !theURL )
	{
		theURL = [NSURL fileURLWithPath: [NSString stringWithFormat: @"/System/Library/Sounds/%@.aiff", resourceName]];
		if( ![theURL checkResourceIsReachableAndReturnError: NULL] )
			theURL = nil;
	}
	
	if( !theURL )
	{
		LEOContextStopWithError( inContext, "Can't find sound '%s'.", instrNameStr );
		return;
	}
	
	ULIMelodyQueue	*	melodyQueue = [[[ULIMelodyQueue alloc] initWithInstrument: theURL] autorelease];
	[melodyQueue addMelody: [NSString stringWithUTF8String: melodyStr]];
	[melodyQueue play];
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


LEOINSTR_START(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)
LEOINSTR(WILDGoInstruction)
LEOINSTR(WILDVisualEffectInstruction)
LEOINSTR(WILDAnswerInstruction)
LEOINSTR(WILDAskInstruction)
LEOINSTR(WILDCreateInstruction)
LEOINSTR(WILDDeleteInstruction)
LEOINSTR(WILDDebugCheckpointInstruction)
LEOINSTR(WILDCreateUserPropertyInstruction)
LEOINSTR(WILDPrintInstruction)
LEOINSTR_LAST(WILDPlayMelodyInstruction)


struct THostCommandEntry	gStacksmithHostCommands[] =
{
	{
		EGoIdentifier, WILD_GO_INSTRUCTION, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EToIdentifier, EHostParameterOptional, WILD_GO_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EVisualIdentifier, WILD_VISUAL_EFFECT_INSTR, 0, 0, '\0',
		{
			{ EHostParamIdentifier, EEffectIdentifier, EHostParameterOptional, WILD_VISUAL_EFFECT_INSTR, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EAnswerIdentifier, WILD_ANSWER_INSTR, 0, 0, '\0',
		{
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EWithIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOrIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOrIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EAskIdentifier, WILD_ASK_INSTR, 0, 0, '\0',
		{
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EWithIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		ECreateIdentifier, WILD_CREATE_USER_PROPERTY_INSTR, 0, 0, 'X',
		{
			{ EHostParamInvisibleIdentifier, EPropertyIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', 'P' },
			{ EHostParamImmediateValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'P', 'p' },
			{ EHostParamLabeledContainer, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'p', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECreateIdentifier, WILD_CREATE_INSTR, 0, 0, 'X',
		{
			{ EHostParamIdentifier, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', 'O' },
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'O', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EDeleteIdentifier, WILD_DELETE_INSTR, BACK_OF_STACK, 0, '\0',
		{
			{ EHostParamContainer, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EDebugIdentifier, WILD_DEBUG_CHECKPOINT_INSTR, 0, 0, '\0',
		{
			{ EHostParamIdentifier, ECheckpointIdentifier, EHostParameterRequired, WILD_DEBUG_CHECKPOINT_INSTR, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EPutIdentifier, WILD_PRINT_INSTR, BACK_OF_STACK, 0, '\0',
		{
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EPlayIdentifier, WILD_PLAY_MELODY_INSTR, 0, 0, '\0',
		{
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamExpressionOrIdentifiersTillLineEnd, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0, '\0',
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	}
};
