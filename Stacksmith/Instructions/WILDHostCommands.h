//
//  WILDHostCommands.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*!
	@header WILDHostCommands
	Instructions and syntax parsing tables for all the Stacksmith-specific commands.
	These are all the one-off commands that Stacksmith offers that don't warrant
	a file of their own, and that aren't cross-platform or that don't make sense
	to build into the Forge core. E.g. anything UI-related or object model-related.
	
	Register them using:
	<pre>
	LEOAddInstructionsToInstructionArray( gStacksmithHostCommandInstructions, WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS, &kFirstStacksmithHostCommandInstruction );
	LEOAddHostCommandsAndOffsetInstructions( gStacksmithHostCommands, kFirstStacksmithHostCommandInstruction );
	</pre>
*/

#include "LEOInstructions.h"
#include "ForgeTypes.h"


/*!
	@enum WILDHostCommandInstructions
	The instruction ID constants Forge will need to add bytecode instructions
	to a script to implement these Stacksmith-specific commands.
	Add kFirstStacksmithHostCommandInstruction to these instruction ID constants
	when generating code.
*/
enum
{
	WILD_GO_INSTR = 0,
	WILD_GO_BACK_INSTR,
	WILD_VISUAL_EFFECT_INSTR,
	WILD_ANSWER_INSTR,
	WILD_ASK_INSTR,
	WILD_CREATE_INSTR,
	WILD_DELETE_INSTR,
	WILD_DEBUG_CHECKPOINT_INSTR,
	WILD_CREATE_USER_PROPERTY_INSTR,
	WILD_DELETE_USER_PROPERTY_INSTR,
	WILD_PRINT_INSTR,
	WILD_PLAY_MELODY_INSTR,
	WILD_START_INSTR,
	WILD_STOP_INSTR,
	WILD_SHOW_INSTR,
	WILD_HIDE_INSTR,
	WILD_WAIT_INSTR,
	WILD_MOVE_INSTR,
	WILD_CHOOSE_INSTR,
	WILD_MARK_INSTR,
	WILD_START_RECORDING_SOUND_INSTR,
	WILD_STOP_RECORDING_SOUND_INSTR,
	WILD_INSERT_SCRIPT_INSTR,
	
	WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS
};


LEOINSTR_DECL(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)

extern LEOInstructionID				kFirstStacksmithHostCommandInstruction;


extern struct THostCommandEntry	gStacksmithHostCommands[];


enum {
	WILDMarkModeClearMark = 0,			// For readability, or this into the bitfield to get same result as leaving out SetMark.
	WILDMarkModeSetMark = (1 << 0),		// If not set, we clear the mark.
	WILDMarkModeMarkAll = (1 << 1)		// If not, first object on stack is the object to mark/unmark.
};
typedef uint32_t	WILDMarkMode;	// param2 in a WILD_MARK_INSTR instruction.
