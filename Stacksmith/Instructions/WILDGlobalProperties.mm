//
//  WILDGlobalProperties.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDGlobalProperties.h"
#import "StacksmithVersion.h"
#import <string.h>
#import <Cocoa/Cocoa.h>
#import "UKSystemInfo.h"
#include "CScriptableObjectValue.h"
#include "CSound.h"
#include "CStack.h"
#include "CStackMac.h"
#include "CCursor.h"
#import "WILDStackWindowController.h"


using namespace Carlson;


#define TOSTRING2(x)	#x
#define TOSTRING(x)		TOSTRING2(x)


size_t	kFirstGlobalPropertyInstruction = 0;


void	LEOSetCursorInstruction( LEOContext* inContext );
void	LEOPushCursorInstruction( LEOContext* inContext );
void	LEOSetVersionInstruction( LEOContext* inContext );
void	LEOPushVersionInstruction( LEOContext* inContext );
void	LEOPushShortVersionInstruction( LEOContext* inContext );
void	LEOPushLongVersionInstruction( LEOContext* inContext );
void	LEOPushPlatformInstruction( LEOContext* inContext );
void	LEOPushPhysicalMemoryInstruction( LEOContext* inContext );
void	LEOPushMachineInstruction( LEOContext* inContext );
void	LEOPushSystemVersionInstruction( LEOContext* inContext );
void	LEOPushTargetInstruction( LEOContext* inContext );
void	LEOPushSoundInstruction( LEOContext* inContext );
void	LEOPushEditBackgroundInstruction( LEOContext* inContext );
void	LEOSetEditBackgroundInstruction( LEOContext* inContext );
void	LEOPushMouseLocationInstruction( LEOContext* inContext );
void	LEOPushMainStackInstruction( LEOContext* inContext );
void	LEOPushFocusedStackInstruction( LEOContext* inContext );


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
	LEOPushIntegerOnStack( inContext, 128, kLEOUnitNone );	// TODO: Actually retrieve actual cursor ID here.
	
	inContext->currentInstruction++;
}


void	LEOSetVersionInstruction( LEOContext* inContext )
{
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	size_t		lineNo = SIZE_T_MAX;
	uint16_t	fileID = 0;
	LEOInstructionsFindLineForInstruction( inContext->currentInstruction, &lineNo, &fileID );
	LEOContextStopWithError( inContext, lineNo, SIZE_T_MAX, fileID, "You can't change the version number." );
	
	inContext->currentInstruction++;
}


void	LEOPushVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = TOSTRING(STACKSMITH_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushShortVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = TOSTRING(STACKSMITH_SHORT_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushLongVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = "Stacksmith " TOSTRING(STACKSMITH_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushPlatformInstruction( LEOContext* inContext )
{
	const char*		theOSStr = "MacOS";
	LEOPushStringValueOnStack( inContext, theOSStr, strlen(theOSStr) );
	
	inContext->currentInstruction++;
}


void	LEOPushSystemVersionInstruction( LEOContext* inContext )
{
	const char*	theSysVersion = [UKSystemVersionString() UTF8String];
	LEOPushStringValueOnStack( inContext, theSysVersion, strlen(theSysVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushPhysicalMemoryInstruction( LEOContext* inContext )
{
	long long 	physMemory = UKPhysicalRAMSize() / 1024U;
	LEOPushIntegerOnStack( inContext, physMemory, kLEOUnitGigabytes );
	
	inContext->currentInstruction++;
}


void	LEOPushMachineInstruction( LEOContext* inContext )
{
	NSString	*	machineStr = UKMachineName();
	const char	*	machineCStr = [machineStr UTF8String];
	LEOPushStringValueOnStack( inContext, machineCStr, strlen(machineCStr) );
	
	inContext->currentInstruction++;
}


void	LEOPushTargetInstruction( LEOContext* inContext )
{
	LEOValuePtr	newVal = LEOPushValueOnStack( inContext, NULL );
	((CScriptContextUserData*) inContext->userData)->GetTarget()->InitValue( newVal, kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


void	LEOPushSoundInstruction( LEOContext* inContext )
{
	LEOPushStringConstantValueOnStack( inContext, CSound::IsDone() ? "done" : "" );
	
	inContext->currentInstruction++;
}


void	LEOPushEditBackgroundInstruction( LEOContext* inContext )
{
	CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;

	LEOPushBooleanOnStack( inContext, userData->GetStack()->GetEditingBackground() );
	
	inContext->currentInstruction++;
}


void	LEOSetEditBackgroundInstruction( LEOContext* inContext )
{
	CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;

	userData->GetStack()->SetEditingBackground( LEOGetValueAsBoolean( inContext->stackEndPtr -1, inContext ) );
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


void	LEOPushMouseLocationInstruction( LEOContext* inContext )
{
	CScriptContextUserData*	userData = (CScriptContextUserData*)inContext->userData;

	LEONumber		l = 0, t = 0;
	CCursor::GetGlobalPosition( &l, &t );
	CStackMac*	stack = (CStackMac*) userData->GetStack();
	l -= stack->GetLeft();
	t -= stack->GetTop();
	LEOPushPointOnStack( inContext, l, t );
	
	inContext->currentInstruction++;
}


void	LEOPushMainStackInstruction( LEOContext* inContext )
{
	CScriptableObject	*	wdObj = nullptr;
	NSWindow			*	wd = [[NSApplication sharedApplication] mainWindow];
	if( wd )
	{
		NSWindowController	*	wc = [wd windowController];
		if( [wc isKindOfClass: [WILDStackWindowController class]] )
		{
			WILDStackWindowController	*	swc = (WILDStackWindowController*)wc;
			CStack	*	theStack = swc.cppStack;
			if( inContext->group == theStack->GetScriptContextGroupObject() )
			{
				wdObj = theStack;
			}
		}
	}
	
	LEOValuePtr		returnValue = inContext->stackEndPtr;
	inContext->stackEndPtr++;
	if( wdObj )
	{
		wdObj->InitValue( returnValue, kLEOKeepReferences, inContext );
	}
	else
	{
		LEOInitUnsetValue( returnValue, kLEOKeepReferences, inContext );
	}
	
	inContext->currentInstruction++;
}


void	LEOPushFocusedStackInstruction( LEOContext* inContext )
{
	CScriptableObject	*	wdObj = nullptr;
	NSWindow			*	wd = [[NSApplication sharedApplication] keyWindow];
	if( wd )
	{
		NSWindowController	*	wc = [wd windowController];
		if( [wc isKindOfClass: [WILDStackWindowController class]] )
		{
			WILDStackWindowController	*	swc = (WILDStackWindowController*)wc;
			CStack	*	theStack = swc.cppStack;
			if( inContext->group == theStack->GetScriptContextGroupObject() )
			{
				wdObj = theStack;
			}
		}
	}
	
	LEOValuePtr		returnValue = inContext->stackEndPtr;
	inContext->stackEndPtr++;
	if( wdObj )
	{
		wdObj->InitValue( returnValue, kLEOKeepReferences, inContext );
	}
	else
	{
		LEOInitUnsetValue( returnValue, kLEOKeepReferences, inContext );
	}
	
	inContext->currentInstruction++;
}


LEOINSTR_START(GlobalProperty,LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOSetCursorInstruction)
LEOINSTR(LEOPushCursorInstruction)
LEOINSTR(LEOPushVersionInstruction)
LEOINSTR(LEOPushShortVersionInstruction)
LEOINSTR(LEOPushLongVersionInstruction)
LEOINSTR(LEOPushPlatformInstruction)
LEOINSTR(LEOPushPhysicalMemoryInstruction)
LEOINSTR(LEOPushMachineInstruction)
LEOINSTR(LEOPushSystemVersionInstruction)
LEOINSTR(LEOPushSoundInstruction)
LEOINSTR(LEOPushEditBackgroundInstruction)
LEOINSTR(LEOSetEditBackgroundInstruction)
LEOINSTR(LEOPushTargetInstruction)
LEOINSTR(LEOPushMouseLocationInstruction)
LEOINSTR(LEOPushMainStackInstruction)
LEOINSTR_LAST(LEOPushFocusedStackInstruction)


struct TGlobalPropertyEntry	gHostGlobalProperties[] =
{
	{ ECursorIdentifier, ELastIdentifier_Sentinel, SET_CURSOR_INSTR, PUSH_CURSOR_INSTR },
	{ EVersionIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_VERSION_INSTR },
	{ EVersionIdentifier, EShortIdentifier, INVALID_INSTR2, PUSH_SHORT_VERSION_INSTR },
	{ EVersionIdentifier, ELongIdentifier, INVALID_INSTR2, PUSH_LONG_VERSION_INSTR },
	{ EPlatformIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_PLATFORM_INSTR },
	{ ESystemVersionIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_SYSTEMVERSION_INSTR },
	{ EPhysicalMemoryIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_PHYSICALMEMORY_INSTR },
	{ EMachineIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_MACHINE_INSTR },
	{ ETargetIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_TARGET_INSTR },
	{ ESoundIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_SOUND_INSTR },
	{ EEditBackgroundIdentifier, ELastIdentifier_Sentinel, SET_EDIT_BACKGROUND_INSTR, PUSH_EDIT_BACKGROUND_INSTR },
	{ EMouseLocationIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_MOUSE_LOCATION_INSTR },
	{ EFocusedStackIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_FOCUSED_STACK_INSTR },
	{ EMainStackIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_MAIN_STACK_INSTR },
	{ ELastIdentifier_Sentinel, ELastIdentifier_Sentinel, INVALID_INSTR2, INVALID_INSTR2 }
};
