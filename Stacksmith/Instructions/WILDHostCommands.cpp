//
//  WILDHostCommands.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include <strings.h>
#include "WILDHostCommands.h"
#include "CScriptableObjectValue.h"
#include "LEOScript.h"
#include "LEORemoteDebugger.h"
#include "LEOContextGroup.h"
#include "CStack.h"
#include "CDocument.h"
#include "CDocumentMac.h"
#include "CRecentCardsList.h"
#include "CAlert.h"
#include "CMessageBox.h"
#include "CSound.h"
#include "CTimer.h"
#include "CGraphicPart.h"
#include <unistd.h>


using namespace Carlson;


static struct { const char* mStringName; TVisualEffectSpeed mSpeed; }	sSpeedNames[EVisualEffectSpeed_Last] =
{
	{ "very slow", EVisualEffectSpeedVerySlow },
	{ "slow", EVisualEffectSpeedSlow },
	{ "", EVisualEffectSpeedNormal },
	{ "fast", EVisualEffectSpeedFast },
	{ "very fast", EVisualEffectSpeedVeryFast },
};


void	WILDGoInstruction( LEOContext* inContext );
void	WILDGoBackInstruction( LEOContext* inContext );
void	WILDVisualEffectInstruction( LEOContext* inContext );
void	WILDAnswerInstruction( LEOContext* inContext );
void	WILDAskInstruction( LEOContext* inContext );
void	WILDCreateInstruction( LEOContext* inContext );
void	WILDDeleteInstruction( LEOContext* inContext );
void	WILDDebugCheckpointInstruction( LEOContext* inContext );
void	WILDCreateUserPropertyInstruction( LEOContext* inContext );
void	WILDDeleteUserPropertyInstruction( LEOContext* inContext );
void	WILDPrintInstruction( LEOContext* inContext );
void	WILDPlayMelodyInstruction( LEOContext* inContext );
void	WILDStartInstruction( LEOContext* inContext );
void	WILDStopInstruction( LEOContext* inContext );
void	WILDShowInstruction( LEOContext* inContext );
void	WILDHideInstruction( LEOContext* inContext );
void	WILDWaitInstruction( LEOContext* inContext );
void	WILDMoveInstruction( LEOContext* inContext );
void	WILDChooseInstruction( LEOContext* inContext );
void	WILDMarkInstruction( LEOContext* inContext );
void	WILDInsertScriptInstruction( LEOContext* inContext );


size_t	kFirstStacksmithHostCommandInstruction = 0;


/*!
	Implements the 'go back' command.
	
	It will use the current visual effect to perform the transition and will
	clear the current visual effect once done.
	
	param1 in the instruction is a TOpenInMode that will be passed to GoThereInNewWindow().
	
	(WILD_GO_BACK_INSTR)
*/
void	WILDGoBackInstruction( LEOContext* inContext )
{
//	LEODebugPrintContext( inContext );

	if( (inContext->flags & kLEOContextResuming) == 0 )	// This is the actual call to this instruction, we're not resuming the script once the asynchronous 'go' has completed after pausing the script (think "continuation"):
	{
		bool					canGoThere = false;
		CScriptableObject*		destinationObject = CRecentCardsList::GetSharedInstance()->PopCard();
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;

		//LEODebugPrintContext( inContext );

		if( destinationObject )
		{
			TOpenInMode	openInMode = inContext->currentInstruction->param1;
		
			LEOPauseContext( inContext );
			
			LEOContextRetain( inContext );
			canGoThere = destinationObject->GoThereInNewWindow( openInMode, userData->GetStack(), NULL,
			[inContext]()
			{
				LEOResumeContext( inContext );
				
				// +++ Should we set the result here to indicate success?
				
				LEOContextRelease(inContext);
			}, userData->GetVisualEffectType(), userData->GetVisualEffectSpeed() );
		}
		if( canGoThere )
			userData->SetStack( destinationObject->GetStack() );
		
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
		
//		CStack		*	frontStack = userData->GetStack();
//		CCard		*	currentCard = frontStack->GetCurrentCard();
//		currentCard->SetTransitionTypeAndSpeed( std::string(), EVisualEffectSpeedNormal );
		
		if( !canGoThere )
		{
			LEOResumeContext( inContext );
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Can't go there." ); // +++ Should we instead set the result here?
		}
	}
	else	// The "go" has completed and resumed the script.
	{
//		LEODebugPrintContext( inContext );
		
		inContext->currentInstruction++;
	}
}


/*!
	Implements the 'go' command. The first (and only required) parameter on the LEO stack must be a
	CScriptableObjectValue (i.e. isa = kLeoValueTypeScriptableObject) on which
	the GoThereInNewWindow() method will be called. If the parameter is a string
	instead, we will assume it is a stack that's not yet open and attempt to
	open that. It will remove its parameters from the LEO stack once it is done.
	
	If the second parameter isn't empty, it is assumed to be a part from which
	the transition is to start (e.g. if we do a "zoom" effect opening the window)
	or to which the window will be attached in the case of a popup window.
	
	It will use the current visual effect to perform the transition and will
	clear the current visual effect once done.
	
	param1 in the instruction is a TOpenInMode that will be passed to GoThereInNewWindow().
	
	(WILD_GO_INSTR)
*/
void	WILDGoInstruction( LEOContext* inContext )
{
//	LEODebugPrintContext( inContext );

	if( (inContext->flags & kLEOContextResuming) == 0 )	// This is the actual call to this instruction, we're not resuming the script once the asynchronous 'go' has completed after pausing the script (think "continuation"):
	{
		LEOValuePtr				theDestination = inContext->stackEndPtr -2;
		LEOValuePtr				theOverPart = inContext->stackEndPtr -1;
		bool					canGoThere = false;
		CScriptableObject*		destinationObject = NULL;
		CPart			*		overPartObject = NULL;
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		CRecentCardsList::GetSharedInstance()->AddCard( userData->GetStack()->GetCurrentCard() );
		LEOValuePtr				theObjectDestination = LEOFollowReferencesAndReturnValueOfType( inContext->stackEndPtr -2, &kLeoValueTypeScriptableObject, inContext );
		theOverPart = LEOFollowReferencesAndReturnValueOfType( inContext->stackEndPtr -1, &kLeoValueTypeScriptableObject, inContext );
		if( theOverPart && theOverPart->base.isa == &kLeoValueTypeScriptableObject )
			overPartObject = dynamic_cast<CPart*>((CScriptableObject*)theOverPart->object.object);

		//LEODebugPrintContext( inContext );

		if( theObjectDestination && theObjectDestination->base.isa == &kLeoValueTypeScriptableObject )
		{
			destinationObject = (CScriptableObject*)theObjectDestination->object.object;
		}
		else if( theDestination )
		{
			char stackName[1024] = { 0 };
			LEOGetValueAsString( theDestination, stackName, sizeof(stackName), inContext );
			destinationObject = userData->GetStack()->GetDocument()->GetStackByName( stackName );
			if( !destinationObject )
			{
				LEOPauseContext( inContext );
				
				LEOContextRetain( inContext );

				CDocumentManager::GetSharedDocumentManager()->OpenDocumentFromURL( std::string(stackName),
				[inContext,overPartObject,userData]( CDocument * inNewDocument )
				{
					LEOResumeContext( inContext );
					
                    if( !inNewDocument )
                    {
                        LEOContextSetLocalVariable( inContext, "result", "Cancel" );  // TODO: Ask "where is..." with an open panel here, then return "Cancel" only if the user canceled that.
                    }
                    else
                    {
                        LEOContextSetLocalVariable( inContext, "result", "" );  // Set the result to empty here to indicate success.
                    }
					
					LEOContextRelease(inContext);
				}, userData->GetVisualEffectType(), userData->GetVisualEffectSpeed(), inContext->group );
				
				LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
				return;
			}
		}
		if( destinationObject )
		{
			TOpenInMode	openInMode = inContext->currentInstruction->param1;
			CStack	*	theStack = destinationObject->GetStack();
			if( theStack && theStack->GetStyle() == EStackStylePopup && overPartObject )
				openInMode |= EOpenInNewWindow;
            
			LEOPauseContext( inContext );
			
			LEOContextRetain( inContext );
			canGoThere = destinationObject->GoThereInNewWindow( openInMode, userData->GetStack(), overPartObject,
			[inContext]()
			{
				LEOResumeContext( inContext );
				
                LEOContextSetLocalVariable( inContext, "result", "" );  // Set the result to empty here to indicate success.
				
				LEOContextRelease(inContext);
			}, userData->GetVisualEffectType(), userData->GetVisualEffectSpeed() );
		}
		if( canGoThere )
			userData->SetStack( destinationObject->GetStack() );
		
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
		
		if( !canGoThere )
		{
			LEOResumeContext( inContext );
            LEOContextSetLocalVariable( inContext, "result", "No such card" );
		}
	}
	else	// The "go" has completed and resumed the script.
	{
//		LEODebugPrintContext( inContext );
		
		inContext->currentInstruction++;
	}
}


/*!
	Implement the 'visual effect' command. This sets the current context user data's
	transition effect to the specified visual effect so the next 'go' command can
	use it.
	
	The only parameter on the stack is a string, the name of the transition to
	use. It will be removed from the stack once this instruction has completed.
	
	(WILD_VISUAL_EFFECT_INSTR)
*/

void	WILDVisualEffectInstruction( LEOContext* inContext )
{
	char effectStr[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -2, effectStr, sizeof(effectStr), inContext );
	char speedStr[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, speedStr, sizeof(speedStr), inContext );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	TVisualEffectSpeed	speed = EVisualEffectSpeedNormal;
	for( size_t x = 0; x < EVisualEffectSpeed_Last; x++ )
	{
		if( strcasecmp( sSpeedNames[x].mStringName, speedStr ) == 0 )
		{
			speed = sSpeedNames[x].mSpeed;
			break;
		}
	}
	
	CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
	
    userData->SetVisualEffectTypeAndSpeed( effectStr, speed );

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
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	char btn1Buf[1024] = { 0 };
	const char*	btn1Str = LEOGetValueAsString( inContext->stackEndPtr -3, btn1Buf, sizeof(btn1Buf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	char btn2Buf[1024] = { 0 };
	const char*	btn2Str = LEOGetValueAsString( inContext->stackEndPtr -2, btn2Buf, sizeof(btn2Buf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	char btn3Buf[1024] = { 0 };
	const char*	btn3Str = LEOGetValueAsString( inContext->stackEndPtr -1, btn3Buf, sizeof(btn3Buf), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	
	size_t	returnValue = CAlert::RunMessageAlert( msgStr, btn1Str, btn2Str, btn3Str );
	
	const char	*hitButtonName = "OK";
	if( returnValue == 1 )
	{
		if( strlen(btn1Str) > 0 )
			hitButtonName = btn1Str;
		else
			hitButtonName = "OK";
	}
	else if( returnValue == 2 )
		hitButtonName = btn2Str;
	else if( returnValue == 3 )
		hitButtonName = btn3Str;
	
    LEOContextSetLocalVariable( inContext, "result", "%s", hitButtonName ); // TODO: Make NUL-safe.
    LEOContextSetLocalVariable( inContext, "it", "%s", hitButtonName ); // TODO: Make NUL-safe.
	
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
	std::string	theAnswer(answerStr);
	
	bool	wasOK = CAlert::RunInputAlert( msgStr, theAnswer );
	
    const char*		hitButtonName = (wasOK ? "OK" : "Cancel");
    LEOContextSetLocalVariable( inContext, "result", "%s", hitButtonName ); // TODO: Make NUL-safe.
    LEOContextSetLocalVariable( inContext, "it", "%s", theAnswer.c_str() ); // TODO: Make NUL-safe.
	
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
	LEOGetValueAsString( inContext->stackEndPtr -3, typeNameBuf, sizeof(typeNameBuf), inContext );
	char nameBuf[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -2, nameBuf, sizeof(nameBuf), inContext );
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( inContext->stackEndPtr -1, &kLeoValueTypeScriptableObject, inContext );
	CScriptableObject*	desiredParent = nullptr;
	if( objectValue )
	{
		LEOValue	trueValue;
		LEOInitBooleanValue( &trueValue, true, kLEOInvalidateReferences, inContext );
		desiredParent = (CScriptableObject*)objectValue->object.object;
	}

	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -3 );

    CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
    CStack				*	frontStack = userData->GetStack();
	CDocument			*	frontDocument = frontStack ? frontStack->GetDocument() : nullptr;
	if( strcasecmp(typeNameBuf,"menu") == 0 )
	{
		CDocument*					desiredDocument = desiredParent ? dynamic_cast<CDocument*>(desiredParent) : frontDocument;
		if( !desiredDocument )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Expected a project after \"of\"." );
			return;
		}

		tinyxml2::XMLDocument   document;
		std::string             xml( "<menu><name>" );
		xml.append( nameBuf );
		xml.append( "</name></menu>" );
		document.Parse( xml.c_str() );
		frontDocument->NewMenuWithElement( document.RootElement() );
	}
	else if( strcasecmp(typeNameBuf,"menuItem") == 0 )
	{
		CMenu*					desiredMenu = desiredParent ? dynamic_cast<CMenu*>(desiredParent) : nullptr;
		if( !desiredMenu )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Expected \"of\" followed by the menu to add the new item to." );
			return;
		}

		tinyxml2::XMLDocument   document;
		std::string             xml( "<menuitem><name>" );
		xml.append( nameBuf );
		xml.append( "</name></menuitem>" );
		document.Parse( xml.c_str() );
		desiredMenu->NewMenuItemWithElement( document.RootElement() );
	}
	else
	{
		CLayer				*	currentLayer = frontStack->GetCurrentLayer();
		tinyxml2::XMLDocument   document;
		std::string             xml( "<part><type>" );
		xml.append( typeNameBuf );
		xml.append( "</type></part>" );
		document.Parse( xml.c_str() );
		CPart * thePart = CPart::NewPartWithElement( document.RootElement(), currentLayer );
		thePart->SetName( nameBuf );
		currentLayer->AddPart( thePart );
		thePart->Release();
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
						(i.e. isa = kLeoValueTypeScriptableObject)
	
	(WILD_CREATE_USER_PROPERTY_INSTR)
*/

void	WILDCreateUserPropertyInstruction( LEOContext* inContext )
{
	char propNameBuf[1024] = { 0 };
	const char*	propNameStr = LEOGetValueAsString( inContext->stackEndPtr -2, propNameBuf, sizeof(propNameBuf), inContext );
	LEOValuePtr objValue = inContext->stackEndPtr -1;
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( objValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
        CScriptableObject*	theObject = (CScriptableObject*) objectValue->object.object;
		theObject->AddUserPropertyNamed( propNameStr );
	}
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
	
	inContext->currentInstruction++;
}


/*!
	Implements the 'delete property' command. Deletes a user property of the specified
	name from the specified object. Only works for properties added using the
	'create property' command. Takes 2 parameters and removes them from the stack on
	completion:
	
	propertyName	-	The name of the property to delete, as a string.
	object			-	The object to remove the property from, as a WILDObjectValue
						(i.e. isa = kLeoValueTypeScriptableObject)
	
	(WILD_DELETE_USER_PROPERTY_INSTR)
*/

void	WILDDeleteUserPropertyInstruction( LEOContext* inContext )
{
	char propNameBuf[1024] = { 0 };
	const char*	propNameStr = LEOGetValueAsString( inContext->stackEndPtr -2, propNameBuf, sizeof(propNameBuf), inContext );
	LEOValuePtr objValue = inContext->stackEndPtr -1;
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( objValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
        CScriptableObject*	theObject = (CScriptableObject*) objectValue->object.object;
		theObject->DeleteUserPropertyNamed( propNameStr );
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	const char* newStr = LEOGetValueAsString( theValue, buf, sizeof(buf), inContext );
	
	CMessageBox::GetSharedInstance()->SetTextContents( newStr );
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		bool	couldDelete = ((CScriptableObject*)objectValue->object.object)->DeleteObject();
		if( !couldDelete )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to delete this object." );
		}
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
 If the parameter is an object instead of an instrument, see if the object can
 be started. If yes, start it instead.
 (WILD_PLAY_MELODY_INSTR)
 */

void	WILDPlayMelodyInstruction( LEOContext* inContext )
{
	CStack		*	frontStack = ((CScriptContextUserData*)inContext->userData)->GetStack();

	bool		couldStart = false;
	LEOValuePtr	theInstrument = inContext->stackEndPtr -2;
	LEOValuePtr	theMelody = inContext->stackEndPtr -1;
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theInstrument, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		CScriptableObject*	thePart = (CScriptableObject*)objectValue->object.object;
		LEOValue	trueValue;
		LEOInitBooleanValue( &trueValue, true, kLEOInvalidateReferences, inContext );
		couldStart = thePart->SetValueForPropertyNamed( &trueValue, inContext, "started", 0, 0 );
		LEOCleanUpValue( &trueValue, kLEOInvalidateReferences, inContext );
	}
	
	if( !couldStart )
	{
		char		instrNameStrBuf[256] = {};
		const char*	instrNameStr = LEOGetValueAsString( theInstrument, instrNameStrBuf, sizeof(instrNameStrBuf), inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return;
		char		melodyStrBuf[256] = {};
		const char*	melodyStr = LEOGetValueAsString( theMelody, melodyStrBuf, sizeof(melodyStrBuf), inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )
			return;
		
		std::string			mediaURL = frontStack->GetDocument()->GetMediaCache().GetMediaURLByNameOfType( instrNameStr, EMediaTypeSound );
			
		if( mediaURL.length() == 0 )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Can't find sound '%s'.", instrNameStr );
			return;
		}
		
		CSound::PlaySoundWithURLAndMelody( mediaURL, melodyStr );
	}
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		LEOValue	trueValue;
		LEOInitBooleanValue( &trueValue, true, kLEOInvalidateReferences, inContext );
		bool	couldStart = ((CScriptableObject*)objectValue->object.object)->SetValueForPropertyNamed( &trueValue, inContext, "started", 0, 0 );
		LEOCleanUpValue( &trueValue, kLEOInvalidateReferences, inContext );
		if( !couldStart )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to start this object." );
		}
	}
	else
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to start this object." );
	}
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		LEOValue	falseValue;
		LEOInitBooleanValue( &falseValue, false, kLEOInvalidateReferences, inContext );
		bool		couldStop = ((CScriptableObject*)objectValue->object.object)->SetValueForPropertyNamed( &falseValue, inContext, "started", 0, 0 );
		LEOCleanUpValue( &falseValue, kLEOInvalidateReferences, inContext );
		if( !couldStop )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to stop this object." );
		}
	}
	else
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to stop this object." );
	}
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		LEOValue	trueValue;
		LEOInitBooleanValue( &trueValue, true, kLEOInvalidateReferences, inContext );
		bool	couldStart = ((CScriptableObject*)objectValue->object.object)->SetValueForPropertyNamed( &trueValue, inContext, "visible", 0, 0 );
		LEOCleanUpValue( &trueValue, kLEOInvalidateReferences, inContext );
		if( !couldStart )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to show this object." );
		}
	}
	else
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to show this object." );
	}
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	if( objectValue )
	{
		LEOValue	falseValue;
		LEOInitBooleanValue( &falseValue, false, kLEOInvalidateReferences, inContext );
		bool		couldStop = ((CScriptableObject*)objectValue->object.object)->SetValueForPropertyNamed( &falseValue, inContext, "visible", 0, 0 );
		LEOCleanUpValue( &falseValue, kLEOInvalidateReferences, inContext );
		if( !couldStop )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to hide this object." );
		}
	}
	else
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to hide this object." );
	}
	
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
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	LEOUnit		theUnit = kLEOUnitNone;
	LEONumber	theDelay = LEOGetValueAsNumber( theValue, &theUnit, inContext );
	if( theUnit != kLEOUnitTicks && theUnit != kLEOUnitNone )	// Convert to ticks (base unit), then later to fractional settings.
	{
		if( gUnitGroupsForLabels[theUnit] != gUnitGroupsForLabels[kLEOUnitTicks] )	// Comparing apples and oranges, fail!
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Expected%s here, found%s.", gUnitLabels[kLEOUnitTicks], gUnitLabels[theUnit] );
			return;
		}
		
		theDelay = LEONumberWithUnitAsUnit(theDelay, theUnit, kLEOUnitTicks );
	}
	
	theDelay /= 60.0;
	
	// Actually wait:
	usleep(theDelay * 1000000.0);

	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
	Animate a movement of an object along a series of points.
 (WILD_MOVE_INSTR)
 */

void	WILDMoveInstruction( LEOContext* inContext )
{
	union LEOValue*	thePoints = inContext->stackEndPtr -1;
	union LEOValue*	theValue = inContext->stackEndPtr -2;
	if( theValue == NULL || theValue->base.isa == NULL
		|| thePoints == NULL || thePoints->base.isa == NULL )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
		return;
	}
	
	theValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
	CPart	*	thePart = nullptr;
	if( theValue && theValue->base.isa == &kLeoValueTypeScriptableObject )
	{
		thePart = dynamic_cast<CPart*>((CScriptableObject*)theValue->object.object);
	}
	if( thePart == nullptr )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "You're trying to use 'move' on something that isn't a part." );
		return;
	}
	
	int			coordIndex = 0;
	int			numCoords = 0;
	
	std::vector<LEONumber>	coordinates;
	union LEOValue			tmpStorage = {};
	char					keyStr[40] = {0};
	
	while( true )
	{
		// See if there's another coordinate pair, X (horizontal) value comes first.
		snprintf( keyStr, sizeof(keyStr)-1, "%d", numCoords +1 );
		LEOValuePtr	currValue = LEOGetValueForKey( thePoints, keyStr, &tmpStorage, kLEOInvalidateReferences, inContext );
		if( currValue == NULL || (inContext->flags & kLEOContextKeepRunning) == 0 )	// No such key.
		{
			inContext->flags |= kLEOContextKeepRunning;
			break;	// We found all the values.
		}
		++numCoords;
		LEOInteger	l = 0, t = 0;
		LEOGetValueAsPoint( currValue, &l, &t, inContext );
		if( currValue == &tmpStorage )
			LEOCleanUpValue( &tmpStorage, kLEOInvalidateReferences, inContext );
		if( (inContext->flags & kLEOContextKeepRunning) == 0 )	// Item wasn't a point? Error!
			return;
		coordinates.push_back( l );
		coordinates.push_back( t );
	}
	
	if( numCoords == 0 )
		return;
	
	numCoords *= 2;
	
	std::vector<LEONumber>	newCoordinates;
	
	CGraphicPart::ConvertPointsToStepSize( coordinates, 1, newCoordinates );
	numCoords = (int)newCoordinates.size();
	
	thePart->Retain();
	CTimer	*	currTimer = new CTimer( 2, [thePart,coordIndex,numCoords,newCoordinates]( CTimer* inTimer ) mutable
	{
		LEOInteger		l = newCoordinates[coordIndex++];
		LEOInteger		t = newCoordinates[coordIndex++];
		LEOInteger		w = thePart->GetRight() -thePart->GetLeft();
		LEOInteger		h = thePart->GetBottom() -thePart->GetTop();
		
		std::cout << coordIndex << std::endl;
		
		// Center the button over the given coordinate:
		l -= w / 2;
		t -= h / 2;
		
		thePart->SetRect( l, t, l +w, t + h );	// Actually position it.
		
		if( coordIndex >= numCoords )
		{
			inTimer->Stop();
			thePart->Release();
			delete inTimer;
		}
	} );
	currTimer->Start();
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
	Implements the 'choose' command. The first parameter must be a
	string, the name of the tool you want.
	
	(WILD_CHOOSE_INSTR)
*/
void	WILDChooseInstruction( LEOContext* inContext )
{
	LEOValuePtr				theValue = inContext->stackEndPtr -1;
	CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;

	char toolName[1024] = { 0 };
	LEOGetValueAsString( theValue, toolName, sizeof(toolName), inContext );
	if( (inContext->flags & kLEOContextKeepRunning) == 0 )
		return;
	TTool		requestedTool = CStack::GetToolFromName( toolName );
	if( requestedTool == ETool_Last )
	{
		size_t		lineNo = SIZE_T_MAX;
		uint16_t	fileID = 0;
		LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
		LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unknown tool \"%s\".", toolName );
		return;
	}
	userData->GetStack()->SetTool( requestedTool );
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
 Pop a value off the back of the stack (or just read it from the given
 BasePointer-relative address) and set its "marked" property to whatever
 value is in param2 (true or false, i.e. 1 or 0).
 (WILD_MARK_INSTR)
 
 param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
 off the stack. Otherwise, this is a basePtr-relative address
 where a value will just be read.
 param2 -	1 to set the marked to true, 0 to set the marked to false.
 */

void	WILDMarkInstruction( LEOContext* inContext )
{
	
	if( inContext->currentInstruction->param2 & WILDMarkModeMarkAll )
	{
		CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;
		userData->GetStack()->SetMarkedOfAllCards( (inContext->currentInstruction->param2 & WILDMarkModeSetMark) == WILDMarkModeSetMark );
	}
	else
	{
		bool			popOffStack = (inContext->currentInstruction->param1 == BACK_OF_STACK);
		union LEOValue*	theValue = popOffStack ? (inContext->stackEndPtr -1) : (inContext->stackBasePtr +inContext->currentInstruction->param1);
		if( theValue == NULL || theValue->base.isa == NULL )
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Internal error: Invalid value." );
			return;
		}
		
		LEOValuePtr	objectValue = LEOFollowReferencesAndReturnValueOfType( theValue, &kLeoValueTypeScriptableObject, inContext );
		if( objectValue )
		{
			LEOValue	trueFalseValue;
			LEOInitBooleanValue( &trueFalseValue, (inContext->currentInstruction->param2 & WILDMarkModeSetMark) == WILDMarkModeSetMark, kLEOInvalidateReferences, inContext );
			bool	couldMark = ((CScriptableObject*)objectValue->object.object)->SetValueForPropertyNamed( &trueFalseValue, inContext, "marked", 0, 0 );
			LEOCleanUpValue( &trueFalseValue, kLEOInvalidateReferences, inContext );
			if( !couldMark )
			{
				size_t		lineNo = SIZE_T_MAX;
				uint16_t	fileID = 0;
				LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
				LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to (un)mark this object." );
			}
		}
		else
		{
			size_t		lineNo = SIZE_T_MAX;
			uint16_t	fileID = 0;
			LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
			LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "Unable to (un)mark this object." );
		}
		
		if( popOffStack )
			LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	}
	
	inContext->currentInstruction++;
}


LEOINSTR_START(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)
LEOINSTR(WILDGoInstruction)
LEOINSTR(WILDGoBackInstruction)
LEOINSTR(WILDVisualEffectInstruction)
LEOINSTR(WILDAnswerInstruction)
LEOINSTR(WILDAskInstruction)
LEOINSTR(WILDCreateInstruction)
LEOINSTR(WILDDeleteInstruction)
LEOINSTR(WILDDebugCheckpointInstruction)
LEOINSTR(WILDCreateUserPropertyInstruction)
LEOINSTR(WILDDeleteUserPropertyInstruction)
LEOINSTR(WILDPrintInstruction)
LEOINSTR(WILDPlayMelodyInstruction)
LEOINSTR(WILDStartInstruction)
LEOINSTR(WILDStopInstruction)
LEOINSTR(WILDShowInstruction)
LEOINSTR(WILDHideInstruction)
LEOINSTR(WILDWaitInstruction)
LEOINSTR(WILDMoveInstruction)
LEOINSTR(WILDChooseInstruction)
LEOINSTR_LAST(WILDMarkInstruction)


struct THostCommandEntry	gStacksmithHostCommands[] =
{
	{
		EGoIdentifier, WILD_GO_INSTR, EOpenInSameWindow, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EBackIdentifier, EHostParameterOptional, WILD_GO_BACK_INSTR, 0, 0, '\0', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamInvisibleIdentifier, EInIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'I' },
			{ EHostParamInvisibleIdentifier, ENewIdentifier, EHostParameterOptional, WILD_GO_INSTR, EOpenInNewWindow, 0, 'I', 'W' },
			{ EHostParamInvisibleIdentifier, EWindowIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'W', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EGoIdentifier, WILD_GO_INSTR, EOpenInSameWindow, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EToIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, EInIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'I' },
			{ EHostParamInvisibleIdentifier, ENewIdentifier, EHostParameterOptional, WILD_GO_INSTR, EOpenInNewWindow, 0, 'I', 'W' },
			{ EHostParamInvisibleIdentifier, EWindowIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'W', 'X' },
			{ EHostParamInvisibleIdentifier, EPopupIdentifier, EHostParameterOptional, WILD_GO_INSTR, EOpenInNewWindow, 0, 'I', 'X' },
			{ EHostParamLabeledContainer, EFromIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EVisualIdentifier, WILD_VISUAL_EFFECT_INSTR, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, EEffectIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamExpressionOrConstant, EVisualIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamExpressionOrConstant, ESpeedIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EAnswerIdentifier, WILD_ANSWER_INSTR, 0, 0, '\0', '\0',
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
		EAskIdentifier, WILD_ASK_INSTR, 0, 0, '\0', '\0',
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
		ECreateIdentifier, WILD_CREATE_USER_PROPERTY_INSTR, 0, 0, '\0', 'X',
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
		ECreateIdentifier, WILD_CREATE_INSTR, 0, 0, '\0', 'X',
		{
			{ EHostParamExpressionOrConstant, EPartIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', 'O' },
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'O', 'X' },
			{ EHostParamLabeledContainer, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EDeleteIdentifier, WILD_DELETE_USER_PROPERTY_INSTR, 0, 0, '\0', 'X',
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
		EDeleteIdentifier, WILD_DELETE_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EDebugIdentifier, WILD_DEBUG_CHECKPOINT_INSTR, 0, 0, '\0', '\0',
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
		EPutIdentifier, WILD_PRINT_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EPlayIdentifier, WILD_PLAY_MELODY_INSTR, 0, 0, '\0', '\0',
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
		EStartIdentifier, WILD_START_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EStopIdentifier, WILD_STOP_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EShowIdentifier, WILD_SHOW_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EHideIdentifier, WILD_HIDE_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EWaitIdentifier, WILD_WAIT_INSTR, BACK_OF_STACK, 0, '\0', '\0',
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
		EChooseIdentifier, WILD_CHOOSE_INSTR, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamInvisibleIdentifier, EToolIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
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
		EMoveIdentifier, WILD_MOVE_INSTR, 0, 0, '\0', 'X',
		{
			{ EHostParamContainer, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamInvisibleIdentifier, EAlongIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', 'y' },
			{ EHostParamInvisibleIdentifier, EToIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', 'y' },
			{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'y', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EMarkIdentifier, WILD_MARK_INSTR, BACK_OF_STACK, WILDMarkModeSetMark, '1', 'X',
		{
			{ EHostParamInvisibleIdentifier, EAllIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '1', 'a' },
			{ EHostParamInvisibleIdentifier, ECardsIdentifier, EHostParameterRequired, WILD_MARK_INSTR, BACK_OF_STACK, WILDMarkModeSetMark | WILDMarkModeMarkAll, 'a', 'X' },
			{ EHostParamContainer, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '1', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EUnmarkIdentifier, WILD_MARK_INSTR, BACK_OF_STACK, WILDMarkModeClearMark, '1', 'X',
		{
			{ EHostParamInvisibleIdentifier, EAllIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '1', 'a' },
			{ EHostParamInvisibleIdentifier, ECardsIdentifier, EHostParameterRequired, WILD_MARK_INSTR, BACK_OF_STACK, WILDMarkModeClearMark | WILDMarkModeMarkAll, 'a', 'X' },
			{ EHostParamContainer, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '1', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0, '\0', '\0',
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
