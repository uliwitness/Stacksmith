//
//  WILDHostCommands.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "WILDHostCommands.h"
#include "WILDObjectValue.h"
#include "WILDDocument.h"
#include "WILDStack.h"
#include "WILDCard.h"
#include "WILDInputPanelController.h"
#include "LEOScript.h"
#include "LEORemoteDebugger.h"
#import "WILDMessageBox.h"
#import "ULIMelodyQueue.h"
#import "LEOContextGroup.h"


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
void	WILDStartInstruction( LEOContext* inContext );
void	WILDStopInstruction( LEOContext* inContext );
void	WILDShowInstruction( LEOContext* inContext );
void	WILDHideInstruction( LEOContext* inContext );
void	WILDWaitInstruction( LEOContext* inContext );


size_t	kFirstStacksmithHostCommandInstruction = 0;


/*!
	Implements the 'go' command. The first (and only) parameter must be a
	WILDObjectValue (i.e. isa = kLeoValueTypeWILDObject) that will be sent
	a goThereInNewWindow: NO message. If the parameter is a string instead,
	we will assume it is a stack that's not yet open and attempt to open that.
	It will remove its parameters from the stack once it is done.
	
	It will use the current visual effect to perform the transition and will
	clear the current visual effect once done.
	
	(WILD_GO_INSTR)
*/
void	WILDGoInstruction( LEOContext* inContext )
{
	LEOValuePtr			theValue = inContext->stackEndPtr -1;
	BOOL				canGoThere = NO;
	id<WILDObject>		destinationObject = nil;
	if( theValue->base.isa == &kLeoValueTypeWILDObject )
	{
		destinationObject = (id<WILDObject>)theValue->object.object;
		canGoThere = [destinationObject goThereInNewWindow: NO];
	}
	else
	{
		char str[1024] = { 0 };
		LEOGetValueAsString( theValue, str, sizeof(str), inContext );
		NSString	*	stackName = [NSString stringWithUTF8String: str];
		WILDStack*	theStack = [WILDDocument openStackNamed: stackName];
		canGoThere = [theStack goThereInNewWindow: NO];
		destinationObject = theStack;
	}
	if( canGoThere )
		((WILDScriptContextUserData*)inContext->userData).currentStack = destinationObject.stack;
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	WILDStack		*	frontStack = [((WILDScriptContextUserData*)inContext->userData) currentStack];
	WILDCard		*	currentCard = [frontStack currentCard];
	[currentCard setTransitionType: nil subtype: nil];
	
	if( !canGoThere )
		LEOContextStopWithError( inContext, "Can't go there." );

	inContext->currentInstruction++;
}


/*!
	Implement the 'visual effect' command. This sets the current card view's
	transition effect to the specified visual effect so the next 'go' command can
	use it.
	
	The only parameter on the stack is a string, the name of the transition to
	use. It will be removed from the stack once this instruction has completed.
	
	(WILD_VISUAL_EFFECT_INSTR)
*/

void	WILDVisualEffectInstruction( LEOContext* inContext )
{
	char str[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, str, sizeof(str), inContext );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	WILDStack			*	frontStack = [((WILDScriptContextUserData*)inContext->userData) currentStack];
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


/*!
	Implement the 'answer' command. Displays an alert panel with a message and
	up to 3 buttons. Parameters are removed from the stack on completion. The
	name of the button the user clicked will be written into the local variables
	'the result' and 'it'.
	
	msg		-	The message to display. The alert will resize vertically to fit
				this message.
	button1 -	The name for the first, leftmost button, or an empty string to
				indicate the button should be named "OK".
	button2 -	The name for the second button, to the right of button 1. Or an
				empty string to indicate only 1 button is desired.
	button3 -	The name for the 3rd button, to the right of button 2, or an
				empty string to indicate no 3rd button is desired.
	
	The rightmost button will be made the 'OK' button and will react to the
	return key.
	
	This command is deprecated. It is here as a concession to Stacksmith's HyperCard
	heritage, but it is recommended you create buttons and text fields on the card
	and let the user perform any actions you desire there.
	
	(WILD_ANSWER_INSTR)
*/

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


/*!
	Implement the 'ask' command. Displays an alert panel with a message and
	an input field, plus OK and Cancel buttons. Parameters are removed from the
	stack on completion. The name of the button the user clicked will be written
	into the local variable 'the result'. The text the user entered into the
	edit field will be written into the local variable 'it'.
	
	msg		-	The message to display. The alert will resize vertically to fit
				this message.
	answer -	A default answer to write into the edit field to pre-fill it.
	
	This command is deprecated. It is here as a concession to Stacksmith's HyperCard
	heritage, but it is recommended you create buttons and text fields on the card
	and let the user perform any actions you desire there.
	
	(WILD_ASK_INSTR)
*/

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


/*!
	Implements the 'create' command (for objects). Use this to create new card
	parts on the current card or current background (if in editBackground mode).
	2 parameters must be pushed on the stack before this is called and will be
	removed on completion:
	
	typeName	-	The type of part to create, i.e. button, field, player or
					browser, as a string.
	objectName	-	The name to give the new object.
	
	(WILD_CREATE_INSTR)
*/

void	WILDCreateInstruction( LEOContext* inContext )
{
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
		WILDStack		*	frontStack = [((WILDScriptContextUserData*)inContext->userData) currentStack];
		WILDCard		*	currentCard = [frontStack currentCard];
		[currentCard performSelector: newObjectAction withObject: newTitle];
	}
	
	inContext->currentInstruction++;
}


/*!
	Enter the debugger at this line. Does nothing if the debugger is not running
	or otherwise has been deactivated.
	
	(WILD_DEBUG_CHECKPOINT_INSTR)
*/

void	WILDDebugCheckpointInstruction( LEOContext* inContext )
{
	LEOInstruction	*	instr = inContext->currentInstruction;
	
	LEORemoteDebuggerAddBreakpoint( instr );			// Ensure debugger knows to stop here.
	LEORemoteDebuggerPreInstructionProc( inContext );	// Trigger debugger.
	LEORemoteDebuggerRemoveBreakpoint( instr );			// Clean up after debugger.
	
	inContext->currentInstruction++;
}


/*!
	Implements the 'create property' command. Adds a user property of the specified
	name to the specified object. From then on this property will be usable just
	like any built-in property of that object. Takes 2 parameters and removes them
	from the stack on completion:
	
	propertyName	-	The name the new property should have, as a string.
	object			-	The object to add the property to, as a WILDObjectValue
						(i.e. isa = kLeoValueTypeWILDObject)
	
	(WILD_CREATE_USER_PROPERTY_INSTR)
*/

void	WILDCreateUserPropertyInstruction( LEOContext* inContext )
{
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
	In Stacksmith, this means showing it in the message box.
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
 from its owner, if it is a chunk, we empty it and remove any excess delimiters.
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
	WILDStack		*	frontStack = [((WILDScriptContextUserData*)inContext->userData) currentStack];

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
		theURL = [NSURL fileURLWithPath: resourceName];
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


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and set its "started" property to TRUE.
 (WILD_START_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDStartInstruction( LEOContext* inContext )
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
		BOOL	couldStart = [(id<WILDObject>)theValue->object.object setValue: (id)kCFBooleanTrue forWILDPropertyNamed: @"started" inRange: NSMakeRange(0,0)];
		if( !couldStart )
			LEOContextStopWithError( inContext, "Unable to start this object." );
	}
	else
		LEOContextStopWithError( inContext, "Unable to start this object." );
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and set its "started" property to FALSE.
 (WILD_STOP_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDStopInstruction( LEOContext* inContext )
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
		BOOL	couldStop = [(id<WILDObject>)theValue->object.object setValue: (id)kCFBooleanFalse forWILDPropertyNamed: @"started" inRange: NSMakeRange(0,0)];
		if( !couldStop )
			LEOContextStopWithError( inContext, "Unable to stop this object." );
	}
	else
		LEOContextStopWithError( inContext, "Unable to stop this object." );
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and set its "visible" property to TRUE.
 (WILD_SHOW_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDShowInstruction( LEOContext* inContext )
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
		BOOL	couldStart = [(id<WILDObject>)theValue->object.object setValue: (id)kCFBooleanTrue forWILDPropertyNamed: @"visible" inRange: NSMakeRange(0,0)];
		if( !couldStart )
			LEOContextStopWithError( inContext, "Unable to show this object." );
	}
	else
		LEOContextStopWithError( inContext, "Unable to show this object." );
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and set its "visible" property to FALSE.
 (WILD_HIDE_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDHideInstruction( LEOContext* inContext )
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
		BOOL	couldStop = [(id<WILDObject>)theValue->object.object setValue: (id)kCFBooleanFalse forWILDPropertyNamed: @"visible" inRange: NSMakeRange(0,0)];
		if( !couldStop )
			LEOContextStopWithError( inContext, "Unable to hide this object." );
	}
	else
		LEOContextStopWithError( inContext, "Unable to hide this object." );
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and take it as a duration to delay the script.
 (WILD_WAIT_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 */

void	WILDWaitInstruction( LEOContext* inContext )
{
	bool			popOffStack = (inContext->currentInstruction->param1 == BACK_OF_STACK);
	union LEOValue*	theValue = popOffStack ? (inContext->stackEndPtr -1) : (inContext->stackBasePtr +inContext->currentInstruction->param1);
	if( theValue == NULL || theValue->base.isa == NULL )
	{
		LEOContextStopWithError( inContext, "Internal error: Invalid value." );
		return;
	}
	
	LEOUnit		theUnit = kLEOUnitNone;
	LEONumber	theDelay = LEOGetValueAsNumber( theValue, &theUnit, inContext );
	if( theUnit != kLEOUnitTicks && theUnit != kLEOUnitNone )	// Convert to ticks (base unit), then later to fractional settings.
	{
		if( gUnitGroupsForLabels[theUnit] != gUnitGroupsForLabels[kLEOUnitTicks] )	// Comparing apples and oranges, fail!
		{
			LEOContextStopWithError( inContext, "Expected%s here, found%s.", gUnitLabels[kLEOUnitTicks], gUnitLabels[theUnit] );
			return;
		}
		
		theDelay = LEONumberWithUnitAsUnit(theDelay, theUnit, kLEOUnitTicks );
	}
	
	theDelay /= 60.0;
	
	// Update all relevant windows once, in case the wait is so the user sees a UI change:
	WILDStack		*	frontStack = [((WILDScriptContextUserData*)inContext->userData) currentStack];
	for( NSWindowController* inWC in frontStack.document.windowControllers )
		[inWC.window display];
	[WILDMessageBox.sharedMessageBox.window display];

	// Actually wait:
	NSTimeInterval	startTime = [NSDate timeIntervalSinceReferenceDate];
	while( ([NSDate timeIntervalSinceReferenceDate] -startTime) < theDelay )
	{
		usleep(8);
	}

	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
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
LEOINSTR(WILDPlayMelodyInstruction)
LEOINSTR(WILDStartInstruction)
LEOINSTR(WILDStopInstruction)
LEOINSTR(WILDShowInstruction)
LEOINSTR(WILDHideInstruction)
LEOINSTR_LAST(WILDWaitInstruction)


struct THostCommandEntry	gStacksmithHostCommands[] =
{
	{
		EGoIdentifier, WILD_GO_INSTR, 0, 0, '\0',
		{
			{ EHostParamInvisibleIdentifier, EToIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
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
			{ EHostParamInvisibleIdentifier, EEffectIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamExpressionOrIdentifiersTillLineEnd, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
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
		EStartIdentifier, WILD_START_INSTR, BACK_OF_STACK, 0, '\0',
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
		EStopIdentifier, WILD_STOP_INSTR, BACK_OF_STACK, 0, '\0',
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
		EShowIdentifier, WILD_SHOW_INSTR, BACK_OF_STACK, 0, '\0',
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
		EHideIdentifier, WILD_HIDE_INSTR, BACK_OF_STACK, 0, '\0',
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
		EWaitIdentifier, WILD_WAIT_INSTR, BACK_OF_STACK, 0, '\0',
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
