//
//  ForgeHostCommandsStacksmith.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#include "LEOInstructions.h"
#include "ForgeTypes.h"


enum
{
	WILD_GO_INSTRUCTION = 0,
	WILD_VISUAL_EFFECT_INSTR,
	WILD_ANSWER_INSTR,
	WILD_ASK_INSTR,
	WILD_CREATE_INSTR,
	WILD_DELETE_INSTR,
	WILD_DEBUG_CHECKPOINT_INSTR,
	WILD_CREATE_USER_PROPERTY_INSTR,
	WILD_PRINT_INSTR,
	WILD_PLAY_MELODY_INSTR,
	
	WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS
};


LEOINSTR_DECL(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)

extern size_t						kFirstStacksmithHostCommandInstruction;


extern struct THostCommandEntry	gStacksmithHostCommands[];
