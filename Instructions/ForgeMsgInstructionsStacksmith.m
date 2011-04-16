/*
 *  ForgeMsgInstructionsStacksmith.c
 *  Leonie
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

/*!
	@header ForgeMsgInstructionsStacksmith
	These functions implement the actual instructions the Leonie bytecode
	interpreter actually understands. Or at least those that are not portable
	between platforms.
*/

#import "Forge.h"
#import "WILDMessageBox.h"


/*!
	Pop a value off the back of the stack (or just read it from the given
	BasePointer-relative address) and present it to the user in string form.
	(PRINT_VALUE_INSTR)
	
	param1	-	If this is BACK_OF_STACK, we're supposed to pop the last item
				off the stack. Otherwise, this is a basePtr-relative address
				where a value will just be read.
*/

void	LEOPrintInstruction( LEOContext* inContext )
{
	char			buf[1024] = { 0 };
	
	bool			popOffStack = (inContext->currentInstruction->param1 == BACK_OF_STACK);
	union LEOValue*	theValue = popOffStack ? (inContext->stackEndPtr -1) : (inContext->stackBasePtr +inContext->currentInstruction->param1);
	LEOGetValueAsString( theValue, buf, sizeof(buf), inContext );
	
	NSString	*	objcString = [NSString stringWithCString: buf encoding: NSUTF8StringEncoding];
	[[WILDMessageBox sharedMessageBox] setStringValue: objcString];
	
	if( popOffStack )
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


LEOInstructionFuncPtr	gMsgInstructions[LEO_NUMBER_OF_MSG_INSTRUCTIONS] =
{
	LEOPrintInstruction
};


const char*		gMsgInstructionNames[LEO_NUMBER_OF_MSG_INSTRUCTIONS] =
{
	"Print"
};
