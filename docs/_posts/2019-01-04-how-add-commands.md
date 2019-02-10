---
layout: post
title:  "How to add new commands to Stacksmith"
date:   2019-01-04 11:21:57 +0100
categories: development
---
To define a new command in Stacksmith, you first define a few instructions that implement these commands and register them using <tt>LEOAddInstructionsToInstructionArray</tt>, then you define the syntax in a table and pass that to <tt>LEOAddHostCommandsAndOffsetInstructions</tt>. That's it.

How to register new instructions
--------------------------------

First, define a header file for your command to hold some symbolic constants for the instructions you need:

	enum
	{
		MY_FROBNITZ_INSTR = 0,
		MY_FROBOZZ_INSTR,
		MY_FROBAR_INSTR,
		
		NUM_FROBNITZ_INSTRUCTIONS
	};

and forward-declare an array of instruction function pointers:

	LEOINSTR_DECL(Frobnitz,NUM_FROBNITZ_INSTRUCTIONS)	// Declares gFrobnitzInstructions global.

Then create a matching implementation file and declare a function that implements the behaviour for each of your instructions. An instruction function looks like:

	void	MyFrobnitzInstruction( LEOContext* inContext )
	{
		// Look ar inContext->currentInstruction to see param1 and param2
		// Last on-stack parameter will be in inContext->stackEndPtr -1, second-to-last at -2 etc.
		
		inContext->currentInstruction++;	// Advance to the next instruction in the script.
	}

Then create the actual definition of your instruction array, one each corresponding to the constants in your enum:

	LEOINSTR_START(Frobnitz,NUM_FROBNITZ_INSTRUCTIONS)
	LEOINSTR(MyFrobnitzInstruction)
	LEOINSTR(MyFrobozzInstruction)
	LEOINSTR_LAST(MyFrobarInstruction)

To make Leonie aware of these instructions, you need to add the instructions to Leonie's internal table of instructions. Leonie already knows some built-in instructions, and you may have already added another batch of instructions for a different command, so you will need to know at which position these instructions have been inserted. We define a global variable to hold this offset:

	size_t						kFirstFrobnitzInstruction;

and also add an <tt>extern</tt> declaration to our header. Now you can go to the host application's <tt>main()</tt> function (or in the case of Stacksmith, to the <tt>-initializeParser</tt> method of the WILDAppDelegate and actually register your instructions:

	LEOAddInstructionsToInstructionArray( gFrobnitzInstructions, NUM_FROBNITZ_INSTRUCTIONS, &kFirstFrobnitzInstruction );

If you were to manually generate your bytecode, you could now add kFirstFrobnitzInstruction to e.g. MY_FROBNITZ_INSTR to get the actual LEOInstructionID to write into the bytecode so Leonie will execute the correct function.



How to add new command syntax
-----------------------------

Imagine you wanted to add a command whose syntax was:

	frobnitz <text> [frobozz <otherText>]

where the second parameter and its 'frobozz' label were optional. Stacksmith does not yet know the identifiers 'frobnitz' and 'frobozz', so the first thing you do is go to <tt>ForgeTypes.h</tt>. At the start of this file, there is a <tt>#define IDENTIFIERS</tt> that defines a mapping between the constants representing an identifier (e.g. <tt>EFunctionIdentifier</tt>) and the actual string it corresponds to in the source file (in lowercase, because Forge converts every character to lowercase before it compares them, thus giving the illusion of a case-insensitive programming language). Go to the last line of that define. Let's say it was

	X1(EPlayIdentifier,"play")
	
Add two more lines so it reads:

	X1(EPlayIdentifier,"play") \
	X1(EFrobnitzIdentifier,"frobnitz") \
	X1(EFrobozzIdentifier,"frobozz")

If you wanted "frob" to be a short form for "frobozz", you could also add an entry:

	X2(EFrobIdentifier,EFrobozzIdentifier,"frob")

Which will map all occurrences of the word "frob" to the EFrobozzIdentifier, too. Now that Forge knows our new identifiers, we can define a syntax table for our command, in a global variable:

	struct THostCommandEntry	gFrobnitzCommands[] =
	{
		{
			EFrobnitzIdentifier, MY_FROBNITZ_INSTR, 0, 0, '\0',
			{
				{ EHostParamExpression, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
				{ EHostParamLabeledExpression, EFrobozzIdentifier, EHostParameterOptional, MY_FROBOZZ_INSTR, 0, 0, '\0', '\0' },
				{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
			}
		},
		{
			ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0, '\0',
			{
				{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
			}
		}
	};

The first line defines the command's initial identifier as EFrobnitzIdentifier, so it starts with "frobnitz" as we want it. It also tells the parser to use the WILD_FROBNITZ_INSTR instruction when this command is matched during parsing. The next two zeroes are the param1 and param2 fields of the instruction, in which you can pass additional information for your instruction function. The following array holds one entry for each parameter, its end marked by a parameter whose type is set to EHostParam_Sentinel. Each parameter entry is defined as:

	type, identifier, optional, instructionID, param1, param2, modeRequired, modeToSet

The first parameter in our example is of type 'immediate value', meaning the first parameter can be any expression (which fulfills our "text" criterion well enough, it could be a string concatenation expression, after all). This expression will be pushed on the stack before our instruction function is called. Since we only have an expression and no identifier labeling it, we pass ELastIdentifier_Sentinel as the identifier to mean 'we don't care'. The first parameter is required, so we say that here. We don't want to change the instruction we compile to, so we pass <tt>INVALID_INSTR2</tt> here, and 0 for param1 and param2.

The second parameter is a labeled expression. That is, an identifier as a label, followed by another expression. The identifier for the label is of course Frobozz, and it is optional. Now, I've arbitrarily decided that although the Frobozz variant of our Frobnitz command looks fairly similar, it will actually be implemented by a completely different instruction, <tt>MY_FROBOZZ_INSTR</tt>. If I specified <tt>INVALID_INSTR2</tt> here as well, both variants of the command would be handled by the <tt>MY_FROBNITZ_INSTR</tt> instruction. If the second parameter is present the second item on the stack will be the second expression. If the second parameter is left out, an empty string will be pushed instead. However, since I specified a different instruction to be used, if the second parameter is missing, the parser will *not* push a second parameter on the stack. Only when it is present will <tt>MY_FROBOZZ_INSTR</tt> be called with two parameters on the stack.

Since we only define one command in this example, the second command simply starts with ELastIdentifier_Sentinel, indicating this is the end of the array.

Now all that's left is registeringyour new command's syntax with Forge. To do that, call

	LEOAddHostCommandsAndOffsetInstructions( gFrobnitzCommands, kFirstFrobnitzInstruction );

sometime at startup, ideally right after you register the Frobnitz instructions. Pass in the kFirstFrobnitzInstruction global, so Forge can offset all the instruction IDs you specify correctly. Of course this also means that you can only use instructions in this syntax entry that you registered together.

If your syntax is more complex, you can take advantage of the <tt>modeRequired</tt> and <tt>modeToSet</tt> fields of parameters. A command starts out in mode '\0'. It will match any parameter whose <tt>modeRequired</tt> is '\0' as well. If you specify any other character in the <tt>modeToSet</tt> of a parameter that matches, it will from then on only look for subsequent parameters that have the same character in <tt>modeRequired</tt>. In addition, you can specify a required terminal state at the top with the command's name. Usually, 'X' is used here. If parsing the command ends, but the mode is not this character, parsing will be considered a failure. This is useful to define parameters as optional only when another parameter is specified instead. If neither is specified, the second one will not set the state to 'X', and parsing will fail as desired, even though both are optional.


Writing a simple instruction function
-------------------------------------

Just as an example, let's implement a typical instruction function like our example above would use it:

	void	MyFrobozzInstruction( LEOContext* inContext )
	{
		LEOValuePtr	stackParam2 = inContext->stackEndPtr -1;	// Was pushed last, so at end of stack.
		LEOValuePtr	stackParam1 = inContext->stackEndPtr -2;
		
		char	stackParam1StrBuf[1024] = { 0 };
		const char*	stackParam1Str = LEOGetValueAsString( stackParam1, stackParam1StrBuf, sizeof(stackParam1StrBuf), inContext );

		char	stackParam2StrBuf[1024] = { 0 };
		const char*	stackParam1Str = LEOGetValueAsString( stackParam2, stackParam2StrBuf, sizeof(stackParam2StrBuf), inContext );
		
		DoAnActuallFrobozz( stackParam1Str, stackParam2Str );
		
		LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -2 );
		
		inContext->currentInstruction++;	// Advance to the next instruction in the script.
	}

First, this calculates the position on the stack of our two parameters. Then it retrieves these values as strings. If they are actual string values, this will return the actual internal string pointers in stackParam1Str and stackParam2Str. If they are other values, it converts them to strings in the stackParam1StrBuf resp. stackParam2StrBuf buffers we provide and returns those in stackParam1Str and stackParam2Str instead.

Once we've extracted the 2 strings, we call the function that does the actual work, DoAnActualFrobozz() and hand the two strings to it (if Frobozzing wasn't such a complex task, we'd probably just do it right there in the instruction function).

Lastly, we remove our 2 parameters from the stack by unwinding the stack by 2 slots, and advance to the next instruction. This is what pretty much all command instructions would do. Only if you are implementing a branching instruction, would you add or subtract different values from the currentInstruction pointer of the context.
