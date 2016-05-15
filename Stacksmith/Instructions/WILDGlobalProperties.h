//
//  WILDGlobalProperties.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*!
	@header WILDGlobalProperties
	Define the instructions and the property name identifier -> instruction
	mappings for the Stacksmith-specific global properties exposed to scripts.
	
	To make these available to the Forge parser and Leonie bytecode interpreter,
	you need to register them using
	<pre>
	LEOAddInstructionsToInstructionArray( gGlobalPropertyInstructions, LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS, &kFirstGlobalPropertyInstruction );
	LEOAddGlobalPropertiesAndOffsetInstructions( gHostGlobalProperties, kFirstGlobalPropertyInstruction );
	</pre>
*/

#include "LEOInstructions.h"
#include "ForgeTypes.h"


/*!
	@enum WILDGlobalPropertyInstructions
	The instruction ID constants Forge will need to add bytecode instructions
	to a script for retrieving or changing our global properties.
	Add kFirstGlobalPropertyInstruction to these instruction ID constants when
	generating code.
*/
enum
{
	SET_CURSOR_INSTR = 0,
	PUSH_CURSOR_INSTR,
	PUSH_VERSION_INSTR,
	PUSH_SHORT_VERSION_INSTR,
	PUSH_LONG_VERSION_INSTR,
	PUSH_PLATFORM_INSTR,
	PUSH_PHYSICALMEMORY_INSTR,
	PUSH_MACHINE_INSTR,
	PUSH_SYSTEMVERSION_INSTR,
	PUSH_SOUND_INSTR,
	PUSH_EDIT_BACKGROUND_INSTR,
	SET_EDIT_BACKGROUND_INSTR,
	PUSH_TARGET_INSTR,
	PUSH_MOUSE_LOCATION_INSTR,
	
	LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS
};


LEOINSTR_DECL(GlobalProperty,LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS)

extern size_t						kFirstGlobalPropertyInstruction;


extern struct TGlobalPropertyEntry	gHostGlobalProperties[];
