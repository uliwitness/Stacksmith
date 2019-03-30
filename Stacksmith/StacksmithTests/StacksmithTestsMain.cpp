//
//  StacksmithTestsMain.cpp
//  StacksmithTests
//
//  Created by Uli Kusterer on 2014-01-26.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include <iostream>
#include "CAttributedString.h"
#include "CStyleSheet.h"
#include "Forge.h"
#include "ForgeTypes.h"
#include "CParseTree.h"
#include <sstream>
#include <fstream>
#include <set>
#include "CMap.h"
#include "CRefCountedObject.h"
#include "CToken.h"


#define FIXING_TESTS		0


#if FIXING_TESTS
#define	TEST_FAIL_PREFIX		"warning: "
#else
#define	TEST_FAIL_PREFIX		"error: "
#endif


enum
{
	EOpenInSameWindow,
	EOpenInNewWindow
};


enum
{
	WILD_GO_INSTR = 0,
	WILD_VISUAL_EFFECT_INSTR,
	WILD_ANSWER_INSTR,
	WILD_ASK_INSTR,
	WILD_CREATE_INSTR,
	WILD_DELETE_INSTR,
	WILD_DEBUG_CHECKPOINT_INSTR,
	WILD_CREATE_USER_PROPERTY_INSTR,
	WILD_PRINT_INSTR,
	WILD_PLAY_MELODY_INSTR,
	WILD_START_INSTR,
	WILD_STOP_INSTR,
	WILD_SHOW_INSTR,
	WILD_HIDE_INSTR,
	WILD_WAIT_INSTR,
	WILD_CHOOSE_INSTR,
	
	WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS
};


enum
{
	WILD_STACK_INSTRUCTION = 0,
	WILD_BACKGROUND_INSTRUCTION,
	WILD_CARD_INSTRUCTION,
	WILD_CARD_FIELD_INSTRUCTION,
	WILD_CARD_BUTTON_INSTRUCTION,
	WILD_CARD_MOVIEPLAYER_INSTRUCTION,
	WILD_CARD_PART_INSTRUCTION,
	WILD_BACKGROUND_FIELD_INSTRUCTION,
	WILD_BACKGROUND_BUTTON_INSTRUCTION,
	WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION,
	WILD_BACKGROUND_PART_INSTRUCTION,
	WILD_NEXT_CARD_INSTRUCTION,
	WILD_PREVIOUS_CARD_INSTRUCTION,
	WILD_FIRST_CARD_INSTRUCTION,
	WILD_LAST_CARD_INSTRUCTION,
	WILD_NEXT_BACKGROUND_INSTRUCTION,
	WILD_PREVIOUS_BACKGROUND_INSTRUCTION,
	WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION,
	WILD_PUSH_ORDINAL_PART_INSTRUCTION,
	WILD_THIS_STACK_INSTRUCTION,
	WILD_THIS_BACKGROUND_INSTRUCTION,
	WILD_THIS_CARD_INSTRUCTION,
	WILD_NUMBER_OF_CARD_BUTTONS_INSTRUCTION,
	WILD_NUMBER_OF_CARD_FIELDS_INSTRUCTION,
	WILD_NUMBER_OF_CARD_MOVIEPLAYERS_INSTRUCTION,
	WILD_NUMBER_OF_CARD_PARTS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_BUTTONS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_FIELDS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_MOVIEPLAYERS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_PARTS_INSTRUCTION,
	WILD_CARD_TIMER_INSTRUCTION,
	WILD_BACKGROUND_TIMER_INSTRUCTION,
	WILD_NUMBER_OF_CARD_TIMERS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_TIMERS_INSTRUCTION,
	WILD_MESSAGE_BOX_INSTRUCTION,
	WILD_MESSAGE_WATCHER_INSTRUCTION,
	WILD_CARD_BROWSER_INSTRUCTION,
	WILD_BACKGROUND_BROWSER_INSTRUCTION,
	WILD_NUMBER_OF_CARD_BROWSERS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUND_BROWSERS_INSTRUCTION,
	WILD_NUMBER_OF_CARDS_INSTRUCTION,
	WILD_NUMBER_OF_BACKGROUNDS_INSTRUCTION,
	WILD_NUMBER_OF_STACKS_INSTRUCTION,
	
	WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS
};


struct THostCommandEntry	gStacksmithHostCommands[] =
{
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
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'P', 'p' },
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


struct THostCommandEntry	gStacksmithHostFunctions[] =
{
	{
		EStackIdentifier, WILD_STACK_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' }
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_PART_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EPartIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_BUTTON_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EButtonIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_FIELD_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EFieldIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_BROWSER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EBrowserIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_TIMER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, ETimerIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamInvisibleIdentifier, EPlayerIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBackgroundIdentifier, WILD_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_BROWSER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EBrowserIdentifier, EHostParameterRequired, WILD_CARD_BROWSER_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EMovieIdentifier, EHostParameterRequired, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterOptional, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, 'B', 'A' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_PART_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EPartIdentifier, EHostParameterRequired, WILD_CARD_PART_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_FIELD_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EFieldIdentifier, EHostParameterRequired, WILD_CARD_FIELD_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_BUTTON_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EButtonIdentifier, EHostParameterRequired, WILD_CARD_BUTTON_INSTRUCTION, 0, 0, '\0', 'A' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFieldIdentifier, WILD_CARD_FIELD_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EButtonIdentifier, WILD_CARD_BUTTON_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EMovieIdentifier, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_CARD_MOVIEPLAYER_INSTRUCTION, 0, 0, '\0', '\0' },
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EBrowserIdentifier, WILD_CARD_BROWSER_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EPartIdentifier, WILD_CARD_PART_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ECardIdentifier, WILD_CARD_INSTRUCTION, 0, 0, '\0', '\0',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'A' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, ECardsIdentifier, EHostParameterRequired, WILD_NUMBER_OF_CARDS_INSTRUCTION, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, EBackgroundsIdentifier, EHostParameterRequired, WILD_NUMBER_OF_BACKGROUNDS_INSTRUCTION, 0, 0, 'A', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, EStacksIdentifier, EHostParameterRequired, WILD_NUMBER_OF_STACKS_INSTRUCTION, 0, 0, 'A', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, 'A', 'B' },
			{ EHostParamInvisibleIdentifier, EButtonsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_BUTTONS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, EFieldsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_FIELDS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'B', 'M' },
			{ EHostParamInvisibleIdentifier, EPlayersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_MOVIEPLAYERS_INSTRUCTION, 0, 0, 'M', 'X' },
			{ EHostParamInvisibleIdentifier, EPartsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_PARTS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamInvisibleIdentifier, ETimersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_BACKGROUND_TIMERS_INSTRUCTION, 0, 0, 'B', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENumberIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EOfIdentifier, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'A' },
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'A', 'C' },
			{ EHostParamInvisibleIdentifier, EButtonsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_BUTTONS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamInvisibleIdentifier, EFieldsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_FIELDS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'C', 'm' },
			{ EHostParamInvisibleIdentifier, EPlayersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_MOVIEPLAYERS_INSTRUCTION, 0, 0, 'm', 'X' },
			{ EHostParamInvisibleIdentifier, EPartsIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_PARTS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamInvisibleIdentifier, ETimersIdentifier, EHostParameterOptional, WILD_NUMBER_OF_CARD_TIMERS_INSTRUCTION, 0, 0, 'C', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ENextIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, WILD_NEXT_CARD_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_NEXT_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EPreviousIdentifier, WILD_PREVIOUS_CARD_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, WILD_PREVIOUS_CARD_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_PREVIOUS_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 32, 0, '\0', 'B' },
			{ EHostParamInvisibleIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+1, 0, 'B', 'x' },
			{ EHostParamInvisibleIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+2, 0, 'B', 'x' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+3, 0, 'B', 'z' },
			{ EHostParamInvisibleIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+3, 0, 'z', 'x' },
			{ EHostParamInvisibleIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 16+0, 0, 'B', 'x' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'x', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, WILD_FIRST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamInvisibleIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 1, 0, 'C', 'x' },
			{ EHostParamInvisibleIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 2, 0, 'C', 'x' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 3, 0, 'C', 'y' },
			{ EHostParamInvisibleIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 3, 0, 'y', 'x' },
			{ EHostParamInvisibleIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 0, 0, 'C', 'x' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'x', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 32, 0, '\0', 'B' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'B', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EFirstIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterRequired, WILD_FIRST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'C', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamInvisibleIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+1, 0, 'B', 'x' },
			{ EHostParamInvisibleIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+2, 0, 'B', 'x' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+3, 0, 'B', 'z' },
			{ EHostParamInvisibleIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+3, 0, 'z', 'x' },
			{ EHostParamInvisibleIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+16+0, 0, 'B', 'x' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'x', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterRequired, WILD_LAST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamInvisibleIdentifier, EButtonIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+1, 0, 'C', 'x' },
			{ EHostParamInvisibleIdentifier, EFieldIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+2, 0, 'C', 'x' },
			{ EHostParamInvisibleIdentifier, EMovieIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+3, 0, 'C', 'y' },
			{ EHostParamInvisibleIdentifier, EPlayerIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+3, 0, 'y', 'x' },
			{ EHostParamInvisibleIdentifier, EPartIdentifier, EHostParameterOptional, WILD_PUSH_ORDINAL_PART_INSTRUCTION, 32+0, 0, 'C', 'x' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'x', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterRequired, WILD_PUSH_ORDINAL_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'B' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'B', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterRequired, WILD_LAST_CARD_INSTRUCTION, 0, 0, '\0', 'C' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'C', 'x' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EThisIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EStackIdentifier, EHostParameterOptional, WILD_THIS_STACK_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, EBackgroundIdentifier, EHostParameterOptional, WILD_THIS_BACKGROUND_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, ECardIdentifier, EHostParameterOptional, WILD_THIS_CARD_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ETimerIdentifier, WILD_CARD_TIMER_INSTRUCTION, 0, 0, '\0', 'X',
		{
			{ EHostParamIdentifier, EIdIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
			{ EHostParamImmediateValue, ELastIdentifier_Sentinel, EHostParameterRequired, INVALID_INSTR2, 0, 0, '\0', 'X' },
			{ EHostParamLabeledValue, EOfIdentifier, EHostParameterOptional, INVALID_INSTR2, 0, 0, 'X', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		EMessageIdentifier, INVALID_INSTR2, 0, 0, '\0', 'X',
		{
			{ EHostParamInvisibleIdentifier, EBoxIdentifier, EHostParameterOptional, WILD_MESSAGE_BOX_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParamInvisibleIdentifier, EWatcherIdentifier, EHostParameterOptional, WILD_MESSAGE_WATCHER_INSTRUCTION, 0, 0, '\0', 'X' },
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	},
	{
		ELastIdentifier_Sentinel, INVALID_INSTR2, 0, 0, '\0', '\0',
		{
			{ EHostParam_Sentinel, ELastIdentifier_Sentinel, EHostParameterOptional, INVALID_INSTR2, 0, 0, '\0', '\0' },
		}
	}
};

LEOINSTR_DECL(StacksmithHostFunction,WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS)

LEOInstructionID				kFirstStacksmithHostFunctionInstruction = 0;


extern struct THostCommandEntry	gStacksmithHostFunctions[];


LEOINSTR_DECL(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)

LEOInstructionID				kFirstStacksmithHostCommandInstruction = 0;


extern struct THostCommandEntry	gStacksmithHostCommands[];


LEOINSTR_START(StacksmithHostFunction,WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS)
LEOINSTR_DUMMY(WILDStackInstruction)
LEOINSTR_DUMMY(WILDBackgroundInstruction)
LEOINSTR_DUMMY(WILDCardInstruction)
LEOINSTR_DUMMY(WILDCardFieldInstruction)
LEOINSTR_DUMMY(WILDCardButtonInstruction)
LEOINSTR_DUMMY(WILDCardMoviePlayerInstruction)
LEOINSTR_DUMMY(WILDCardPartInstruction)
LEOINSTR_DUMMY(WILDBackgroundFieldInstruction)
LEOINSTR_DUMMY(WILDBackgroundButtonInstruction)
LEOINSTR_DUMMY(WILDBackgroundMoviePlayerInstruction)
LEOINSTR_DUMMY(WILDBackgroundPartInstruction)
LEOINSTR_DUMMY(WILDNextCardInstruction)
LEOINSTR_DUMMY(WILDPreviousCardInstruction)
LEOINSTR_DUMMY(WILDFirstCardInstruction)
LEOINSTR_DUMMY(WILDLastCardInstruction)
LEOINSTR_DUMMY(WILDNextBackgroundInstruction)
LEOINSTR_DUMMY(WILDPreviousBackgroundInstruction)
LEOINSTR_DUMMY(WILDPushOrdinalBackgroundInstruction)
LEOINSTR_DUMMY(WILDPushOrdinalPartInstruction)
LEOINSTR_DUMMY(WILDThisStackInstruction)
LEOINSTR_DUMMY(WILDThisBackgroundInstruction)
LEOINSTR_DUMMY(WILDThisCardInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardButtonsInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardFieldsInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardMoviePlayersInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardPartsInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundButtonsInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundFieldsInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundMoviePlayersInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundPartsInstruction)
LEOINSTR_DUMMY(WILDCardTimerInstruction)
LEOINSTR_DUMMY(WILDBackgroundTimerInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardTimersInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundTimersInstruction)
LEOINSTR_DUMMY(WILDMessageBoxInstruction)
LEOINSTR_DUMMY(WILDMessageWatcherInstruction)
LEOINSTR_DUMMY(WILDCardBrowserInstruction)
LEOINSTR_DUMMY(WILDBackgroundBrowserInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardBrowsersInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundBrowsersInstruction)
LEOINSTR_DUMMY(WILDNumberOfCardsInstruction)
LEOINSTR_DUMMY(WILDNumberOfBackgroundsInstruction)
LEOINSTR_DUMMY_LAST(WILDNumberOfStacksInstruction)


LEOINSTR_START(StacksmithHostCommand,WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS)
LEOINSTR_DUMMY(WILDGoInstruction)
LEOINSTR_DUMMY(WILDVisualEffectInstruction)
LEOINSTR_DUMMY(WILDAnswerInstruction)
LEOINSTR_DUMMY(WILDAskInstruction)
LEOINSTR_DUMMY(WILDCreateInstruction)
LEOINSTR_DUMMY(WILDDeleteInstruction)
LEOINSTR_DUMMY(WILDDebugCheckpointInstruction)
LEOINSTR_DUMMY(WILDCreateUserPropertyInstruction)
LEOINSTR_DUMMY(WILDPrintInstruction)
LEOINSTR_DUMMY(WILDPlayMelodyInstruction)
LEOINSTR_DUMMY(WILDStartInstruction)
LEOINSTR_DUMMY(WILDStopInstruction)
LEOINSTR_DUMMY(WILDShowInstruction)
LEOINSTR_DUMMY(WILDHideInstruction)
LEOINSTR_DUMMY(WILDWaitInstruction)
LEOINSTR_DUMMY_LAST(WILDChooseInstruction)


using namespace Carlson;


std::ostream& operator << ( std::ostream& stream, const std::deque<CToken>::iterator& currToken )
{
	stream << currToken->GetDescription();
	
	return stream;
}


class TestRefCountedObject : public CRefCountedObject
{
public:
	TestRefCountedObject()	{ sExistingObjects++; };

	inline size_t		GetRefCount()	{ return mRefCount; };	// Only for unit tests.
	
	static size_t	sExistingObjects;
	
protected:
	virtual ~TestRefCountedObject()	{ sExistingObjects--; };
};


size_t	TestRefCountedObject::sExistingObjects = 0;


static size_t	sFailed = 0, sPassed = 0;


void	WILDTest( const char* expr, const char* found, const char* expected )
{
	bool		testPassed = false;
	if( found == NULL || expected == NULL )
		testPassed = (expected == found);
	else
		testPassed = (strcmp(expected, found) == 0);
	if( testPassed )
	{
		std::cout << "note: " << expr << std::endl;
		sPassed++;
	}
	else
	{
		std::cout << TEST_FAIL_PREFIX << expr << " -> \"" << found << "\" == \"" << expected << "\"" << std::endl;
		sFailed++;
		
		std::stringstream expectedFileName;
		expectedFileName << "expected_" << expr << ".txt";
		std::ofstream expectedFile(expectedFileName.str());
		expectedFile << expected;
		
		std::stringstream foundFileName;
		foundFileName << "found_" << expr << ".txt";
		std::ofstream foundFile(foundFileName.str());
		foundFile << found;
		
	}
}


template<class T>
void	WILDTest( const char* expr, T found, T expected )
{
	if( expected == found )
	{
		std::cout << "note: " << expr << std::endl;
		sPassed++;
	}
	else
	{
		std::cout << TEST_FAIL_PREFIX << expr << " -> " << found << " == " << expected << std::endl;
		sFailed++;
	}
}



int main(int argc, const char * argv[])
{
	{
		CAttributedString		attrStr;
		CStyleSheet				styles;
		tinyxml2::XMLDocument	doc;
		
		doc.Parse( "<text>This is <span class=\"style1\">absolutely</span><span class=\"style2\"> fabulous</span></text>" );
		
		tinyxml2::XMLElement*	elem = doc.FirstChildElement( "text" );
		
		styles.LoadFromStream( ".style1 { font-weight: bold; } .style2 { font-style: italic; }" );
		std::string	css = styles.GetCSS();
		
		WILDTest( "Read & Output round trip.", css.c_str(), ".style1\n{\n	font-weight: bold;\n}\n.style2\n{\n	font-style: italic;\n}\n" );
		WILDTest( "Number of classes", styles.GetNumClasses(), size_t(2) );
		WILDTest( ".style1 is there", styles.GetClassAtIndex(0).c_str(), ".style1" );
		auto styleOne = styles.GetStyleForClass("style1");
		WILDTest( ".style1 contains 1 style", styleOne.size(), size_t(1) );
		WILDTest( ".style1 is bold", styleOne["font-weight"].c_str(), "bold" );
		WILDTest( ".style2 is there", styles.GetClassAtIndex(1).c_str(), ".style2" );
		auto styleTwo = styles.GetStyleForClass("style2");
		WILDTest( ".style2 contains 1 style", styleTwo.size(), size_t(1) );
		WILDTest( ".style2 is italic", styleTwo["font-style"].c_str(), "italic" );
		
		attrStr.LoadFromElementWithStyles( elem, styles );
		
		CStyleSheet				writtenStyles;
		CAttributedString		loadedStr;
		tinyxml2::XMLDocument	doc2;
		tinyxml2::XMLElement*	elem2 = doc2.NewElement( "text" );
		doc2.InsertEndChild(elem2);
		attrStr.SaveToXMLDocumentElementStyleSheet( &doc2, elem2, &writtenStyles );

		WILDTest( "Output & Read round trip.", writtenStyles.GetCSS().c_str(), ".style1\n{\n	font-weight: bold;\n}\n.style2\n{\n	font-style: italic;\n}\n" );
		WILDTest( "Number of classes", writtenStyles.GetNumClasses(), size_t(2) );
		WILDTest( ".style1 is there", writtenStyles.GetClassAtIndex(0).c_str(), ".style1" );
		styleOne = writtenStyles.GetStyleForClass("style1");
		WILDTest( ".style1 contains 1 style", styleOne.size(), size_t(1) );
		WILDTest( ".style1 is bold", styleOne["font-weight"].c_str(), "bold" );
		WILDTest( ".style2 is there", writtenStyles.GetClassAtIndex(1).c_str(), ".style2" );
		styleTwo = writtenStyles.GetStyleForClass("style2");
		WILDTest( ".style2 contains 1 style", styleTwo.size(), size_t(1) );
		WILDTest( ".style2 is italic", styleTwo["font-style"].c_str(), "italic" );
	}
	
	{
		CAttributedString		attrStr;
		CStyleSheet				styles;
		tinyxml2::XMLDocument	doc;
		
		doc.Parse( "<text>othervalue:foo\n<span class=\"style2\">somestuff:This</span>\navalue:123.457\ncurrentbutton:First Choice\nd:\nb:\nc:\na:\n</text>" );
		
		tinyxml2::XMLElement*	elem = doc.FirstChildElement( "text" );
		
		styles.LoadFromStream( ".style1 { font-weight: bold; } .style2 { font-style: italic; }" );
		std::string	css = styles.GetCSS();
		
		WILDTest( "Read & Output round trip.", css.c_str(), ".style1\n{\n	font-weight: bold;\n}\n.style2\n{\n	font-style: italic;\n}\n" );
		WILDTest( "Number of classes", styles.GetNumClasses(), size_t(2) );
		WILDTest( ".style1 is there", styles.GetClassAtIndex(0).c_str(), ".style1" );
		auto styleOne = styles.GetStyleForClass("style1");
		WILDTest( ".style1 contains 1 style", styleOne.size(), size_t(1) );
		WILDTest( ".style1 is bold", styleOne["font-weight"].c_str(), "bold" );
		WILDTest( ".style2 is there", styles.GetClassAtIndex(1).c_str(), ".style2" );
		auto styleTwo = styles.GetStyleForClass("style2");
		WILDTest( ".style2 contains 1 style", styleTwo.size(), size_t(1) );
		WILDTest( ".style2 is italic", styleTwo["font-style"].c_str(), "italic" );
		
		attrStr.LoadFromElementWithStyles( elem, styles );
		std::stringstream	stylesStr;
		attrStr.Dump(stylesStr);
		
		WILDTest( "styles were read correctly", stylesStr.str().c_str(), "othervalue:foo\n<span style=\"font-style:italic;\">somestuff:This</span>\navalue:123.457\ncurrentbutton:First Choice\nd:\nb:\nc:\na:\n" );
	}
		
	// Set up some parser tables (but not enough to actually generate bytecode) to be able to test the parser:
	LEOInitInstructionArray();
	LEOAddInstructionsToInstructionArray( gStacksmithHostCommandInstructions, WILD_NUMBER_OF_HOST_COMMAND_INSTRUCTIONS, &kFirstStacksmithHostCommandInstruction );
	LEOAddInstructionsToInstructionArray( gStacksmithHostFunctionInstructions, WILD_NUMBER_OF_HOST_FUNCTION_INSTRUCTIONS, &kFirstStacksmithHostFunctionInstruction );
	LEOAddHostFunctionsAndOffsetInstructions( gStacksmithHostFunctions, kFirstStacksmithHostFunctionInstruction );
	LEOAddHostCommandsAndOffsetInstructions( gStacksmithHostCommands, kFirstStacksmithHostCommandInstruction );
	uint16_t	theFileID = LEOFileIDForFileName("filename");
	
	{
		const char*	errMsg = NULL;
		size_t		errLine = 0, errOffset = 0;
		TMessageType type = EMessageTypeInvalid;
		
		const char*scriptOne = "on mouseUp\n\tput card field 1 into theArray\n\tset the currentButton of theArray to the short name of me\n\tput theArray into card field 1\nend mouseUp";
		const char*resultOne = "Command mouseUp\n{\n	# LINE 2\n	Command \"Put\"\n	{\n		Operator Call \"WILDCardFieldInstruction\"\n		{\n			\"\"\n			int( 1 )\n			\"\"\n		}\n		localVar( var_thearray )\n	}\n	# LINE 3\n	Command \"Put\"\n	{\n		Property \"short name\"\n		{\n			Operator Call \"LEONoOpInstruction\"\n			{\n			}\n		}\n		Property \"currentbutton\"\n		{\n			localVar( var_thearray )\n		}\n	}\n	# LINE 4\n	Command \"Put\"\n	{\n		localVar( var_thearray )\n		Operator Call \"WILDCardFieldInstruction\"\n		{\n			\"\"\n			int( 1 )\n			\"\"\n		}\n	}\n}\n";
		LEOParseTree*	tree = LEOParseTreeCreateFromUTF8Characters( scriptOne, strlen(scriptOne), theFileID );
		std::stringstream	sstream;
		((Carlson::CParseTree*)tree)->DebugPrint( sstream, 0 );
		WILDTest( "Test a few object descriptors", sstream.str().c_str(), resultOne );
		LEOParserGetNonFatalErrorMessageAtIndex( 0, &errMsg, &errLine, &errOffset, &type );
		WILDTest( "Test a few object descriptors (2)", errMsg, NULL );
		LEOCleanUpParseTree(tree);

		const char*scriptTwo = "on mouseUp\n\tif foo is true then\n\tput \"Yay me!\"\n\tend if\nend mouseUp";
		const char*resultTwo = "Command mouseUp\n{\n	# LINE 2\n	If (\n	Operator Call \"LEOEqualOperatorInstruction\"\n	{\n		localVar( var_foo )\n		true\n	}\n	)\n	{\n		# LINE 3\n		Operator Call \"WILDPrintInstruction\"\n		{\n			\"Yay me!\"\n		}\n	}\n}\n";
		tree = LEOParseTreeCreateFromUTF8Characters( scriptTwo, strlen(scriptTwo), theFileID );
		std::stringstream	sstream2;
		((Carlson::CParseTree*)tree)->DebugPrint( sstream2, 0 );
		WILDTest( "Test conditionals parsing", sstream2.str().c_str(), resultTwo );
		LEOParserGetNonFatalErrorMessageAtIndex( 0, &errMsg, &errLine, &errOffset, &type );
		WILDTest( "Test conditionals parsing (2)", errMsg, NULL );
		LEOCleanUpParseTree(tree);

		const char*script3 = "on selectionChange\n	put line the selectedLine of me of me into cd fld 2\n	download “http://www.zathras.de” to cd fld 2\n	for each chunk\n		put size of the download\n	when done\n		put “Done”\n	end download\n	if foo is true then\n	put boo\n	end if\n	answer “Huh”\nend selectionChange";
		const char*result3 = "Command selectionChange\n{\n	# LINE 2\n	Command \"Put\"\n	{\n		Function Call \"MakeChunkConst\"\n		{\n			Operator Call \"LEONoOpInstruction\"\n			{\n			}\n			int( 4 )\n			Property \"selectedline\"\n			{\n				Operator Call \"LEONoOpInstruction\"\n				{\n				}\n			}\n			Property \"selectedline\"\n			{\n				Operator Call \"LEONoOpInstruction\"\n				{\n				}\n			}\n		}\n		Operator Call \"WILDCardFieldInstruction\"\n		{\n			\"\"\n			int( 2 )\n			\"\"\n		}\n	}\n	# LINE 3\n	Command \"download\"\n	{\n		\"http://www.zathras.de\"\n		Operator Call \"WILDCardFieldInstruction\"\n		{\n			\"\"\n			int( 2 )\n			\"\"\n		}\n		\"::downloadProgress:0\"\n		\"::downloadCompletion:1\"\n	}\n	# LINE 9\n	If (\n	Operator Call \"LEOEqualOperatorInstruction\"\n	{\n		localVar( var_foo )\n		true\n	}\n	)\n	{\n		# LINE 10\n		Operator Call \"WILDPrintInstruction\"\n		{\n			localVar( var_boo )\n		}\n	}\n	# LINE 12\n	Operator Call \"WILDAnswerInstruction\"\n	{\n		\"Huh\"\n		\"\"\n		\"\"\n		\"\"\n	}\n}\nCommand ::downloadProgress:0\n{\n	Command \"GetParameter\"\n	{\n		localVar( download )\n		int( 0 )\n	}\n	# LINE 5\n	Operator Call \"WILDPrintInstruction\"\n	{\n		Property \"size\"\n		{\n			localVar( download )\n		}\n	}\n}\nCommand ::downloadCompletion:1\n{\n	Command \"GetParameter\"\n	{\n		localVar( download )\n		int( 0 )\n	}\n	# LINE 7\n	Operator Call \"WILDPrintInstruction\"\n	{\n		\"Done\"\n	}\n}\n";
		tree = LEOParseTreeCreateFromUTF8Characters( script3, strlen(script3), theFileID );
		std::stringstream	sstream3;
		((Carlson::CParseTree*)tree)->DebugPrint( sstream3, 0 );
		WILDTest( "Test conditionals after download parsing", sstream3.str().c_str(), result3 );
		LEOParserGetNonFatalErrorMessageAtIndex( 0, &errMsg, &errLine, &errOffset, &type );
		WILDTest( "Test conditionals after download parsing (2)", errMsg, NULL );
		LEOCleanUpParseTree(tree);
	}
	
	{
		const char*	code = "on meh\nif foo = true then put \"yay\" else put \"nay\"\n"
		"if foo = true then put \"yay\"\nelse put \"nay\"\n"
		"if foo = true\nthen put \"yay\" else put \"nay\"\n"
		"if foo = true then\nput \"yay\"\nelse put \"nay\"\n"
		"if foo = true then\nput \"yay\"\nelse\nput \"nay\"\nend if\n"
		"if foo = true\nthen\nput \"yay\"\nelse\nput \"nay\"\nend if\n"
		"if foo = true then put \"yay\"\nelse\nput \"nay\"\nend if\n"
		"if foo = true then\nelse\nend if\n"
		"if foo = true then put \"yay\"\nelse\n\nend if\n"
		"end meh";
		const char*		expectedText = "on meh\n\tif foo = true then put \"yay\" else put \"nay\"\n"
		"\tif foo = true then put \"yay\"\n\telse put \"nay\"\n"
		"\tif foo = true\n\tthen put \"yay\" else put \"nay\"\n"
		"\tif foo = true then\n\t\tput \"yay\"\n\telse put \"nay\"\n"
		"\tif foo = true then\n\t\tput \"yay\"\n\telse\n\t\tput \"nay\"\n\tend if\n"
		"\tif foo = true\n\tthen\n\t\tput \"yay\"\n\telse\n\t\tput \"nay\"\n\tend if\n"
		"\tif foo = true then put \"yay\"\n\telse\n\t\tput \"nay\"\n\tend if\n"
		"\tif foo = true then\n\telse\n\tend if\n"
		"\tif foo = true then put \"yay\"\n\telse\n\t\t\n\tend if\n"
		"end meh";
		LEOParseTree*	tree = LEOParseTreeCreateFromUTF8Characters( code, strlen(code), theFileID );
		LEODisplayInfoTable*	lit = LEODisplayInfoTableCreateForParseTree( tree );
		char*	theText = NULL;
		size_t	theLength = 0;
		LEODisplayInfoTableApplyToText( lit, code, strlen(code), &theText, &theLength, NULL, NULL );
		WILDTest( "If-then indentation is done right.", theText, expectedText );
		free( theText );
	}

	{
		const char*	code = "on selectionChange\nput line the selectedLine of me of me into cd fld 2\ndownload “http://www.zathras.de” to cd fld 2\nfor each chunk\nput size of the download\nwhen done\nput “Done”\nend download\nif foo is true then\nput doh\nend if\nanswer “Huh”\nend selectionChange";
		const char*		expectedText = "on selectionChange\n\tput line the selectedLine of me of me into cd fld 2\n\tdownload “http://www.zathras.de” to cd fld 2\n\tfor each chunk\n\t\tput size of the download\n\twhen done\n\t\tput “Done”\n\tend download\n\tif foo is true then\n\t\tput doh\n\tend if\n\tanswer “Huh”\nend selectionChange";
		LEOParseTree*	tree = LEOParseTreeCreateFromUTF8Characters( code, strlen(code), theFileID );
		LEODisplayInfoTable*	lit = LEODisplayInfoTableCreateForParseTree( tree );
		char*	theText = NULL;
		size_t	theLength = 0;
		LEODisplayInfoTableApplyToText( lit, code, strlen(code), &theText, &theLength, NULL, NULL );
		WILDTest( "Field descriptors & downloads mixed are indented right.", theText, expectedText );
		free( theText );
	}
	
	{
		CMap<std::string>	testMap;
		testMap["boom"] = "This is boom.";
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Test one CMap insertion", testMap["Boom"].c_str(), "This is boom." );
		testMap["FOO"] = "This is foo uppercase.";
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Test uppercase CMap insertion", testMap["foo"].c_str(), "This is foo uppercase." );
		testMap["foo"] = "This is foo lowercase.";
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Test lowercase CMap insertion", testMap["foo"].c_str(), "This is foo lowercase." );
		testMap["baz"] = "This is baz.";
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Test third CMap insertion", testMap["BAZ"].c_str(), "This is baz." );
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Verify entry 'boom' hasn't changed.", testMap["Boom"].c_str(), "This is boom." );
		#if FIXING_TESTS
		testMap.Dump();
		#endif
		WILDTest( "Verify entry 'foo' hasn't changed.", testMap["foo"].c_str(), "This is foo lowercase." );
	}
	
	{
		TestRefCountedObject*	obj = new TestRefCountedObject;
		WILDTest( "CRefCountedObject created with retain count 1.", obj->GetRefCount(), (size_t)1 );
		TestRefCountedObject*	obj2 = new TestRefCountedObject;
		WILDTest( "CRefCountedObject created with retain count 1.", obj2->GetRefCount(), (size_t)1 );
		
		{
		CRefCountedObjectRef<TestRefCountedObject>		smartPtr;
		smartPtr = obj;
		WILDTest( "CRefCountedObjectRef retains.", obj->GetRefCount(), (size_t)2 );
		
		smartPtr = obj2;
		WILDTest( "CRefCountedObjectRef retains on assignment.", obj2->GetRefCount(), (size_t)2 );
		WILDTest( "CRefCountedObjectRef releases on assignment.", obj->GetRefCount(), (size_t)1 );
		}
		
		WILDTest( "CRefCountedObjectRef releases on destruction.", obj2->GetRefCount(), (size_t)1 );
		
		obj->Release();
		WILDTest( "CRefCountedObject destructed on last Release().", TestRefCountedObject::sExistingObjects, (size_t)1 );
		
		obj2->Release();
		WILDTest( "CRefCountedObject destructed on last Release().", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}
	
	
	{
		{
			CAutoreleasePool		pool;
			TestRefCountedObject*	obj = new TestRefCountedObject;
			obj->Autorelease();
		}
		WILDTest( "CRefCountedObject destructed when autorelease pool goes out of scope.", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}

	{
		{
			std::vector<CRefCountedObjectRef<TestRefCountedObject>>	retainingList;
			TestRefCountedObject*	obj = new TestRefCountedObject;
			retainingList.push_back(obj);
			WILDTest( "CRefCountedObjectRef in vector retains properly.", obj->GetRefCount(), (size_t)2 );
			obj->Release();
			WILDTest( "CRefCountedObjectRef in vector retains properly after release.", obj->GetRefCount(), (size_t)1 );
		}
		WILDTest( "CRefCountedObject destructed when vector goes out of scope.", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}
	
	{
		std::vector<CRefCountedObjectRef<TestRefCountedObject>>	retainingList;
		TestRefCountedObject*	obj = new TestRefCountedObject;
		retainingList.push_back(obj);
		WILDTest( "CRefCountedObjectRef in vector retains properly (2).", obj->GetRefCount(), (size_t)2 );
		obj->Release();
		WILDTest( "CRefCountedObjectRef in vector retains properly after release.", obj->GetRefCount(), (size_t)1 );
		retainingList.erase( retainingList.begin() );
		WILDTest( "CRefCountedObject destructed when erased from vector.", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}

	{
		{
			std::set<CRefCountedObjectRef<TestRefCountedObject>>	retainingList;
			TestRefCountedObject*	obj = new TestRefCountedObject;
			retainingList.insert(obj);
			WILDTest( "CRefCountedObjectRef in set retains properly.", obj->GetRefCount(), (size_t)2 );
			obj->Release();
			WILDTest( "CRefCountedObjectRef in set retains properly after release.", obj->GetRefCount(), (size_t)1 );
		}
		WILDTest( "CRefCountedObject destructed when vector goes out of scope.", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}
	
	{
		std::set<CRefCountedObjectRef<TestRefCountedObject>>	retainingList;
		TestRefCountedObject*	obj = new TestRefCountedObject;
		retainingList.insert(obj);
		WILDTest( "CRefCountedObjectRef in set retains properly (2).", obj->GetRefCount(), (size_t)2 );
		obj->Release();
		WILDTest( "CRefCountedObjectRef in set retains properly after release.", obj->GetRefCount(), (size_t)1 );
		retainingList.erase( retainingList.begin() );
		WILDTest( "CRefCountedObject destructed when erased from set.", TestRefCountedObject::sExistingObjects, (size_t)0 );
	}

	{
		void*		rebecca = (void*)1;
		void*		tyler = (void*)2;
		void*		ruth = (void*)3;
		
		WILDTest( "Initial debug name is \"Rebecca\".", CRefCountedObject::DebugNameForPointer( rebecca ), "Rebecca" );
		WILDTest( "Second debug name is \"Tyler\".", CRefCountedObject::DebugNameForPointer( tyler ), "Tyler" );
		WILDTest( "third debug name is \"Ruth\".", CRefCountedObject::DebugNameForPointer( ruth ), "Ruth" );
		
		WILDTest( "Retrieving name for initial pointer again.", CRefCountedObject::DebugNameForPointer( rebecca ), "Rebecca" );
		WILDTest( "Retrieving name for second pointer again.", CRefCountedObject::DebugNameForPointer( tyler ), "Tyler" );
		WILDTest( "Retrieving name for third pointer again.", CRefCountedObject::DebugNameForPointer( ruth ), "Ruth" );
		WILDTest( "Retrieving name for third pointer a third time.", CRefCountedObject::DebugNameForPointer( ruth ), "Ruth" );
	}
	
	{
		const char*			testText1 = "on answer messageName";
		std::deque<CToken>	tokens1 = CTokenizer::TokenListFromText( testText1, strlen(testText1) );
		std::deque<CToken>::iterator currentToken1 = tokens1.begin();
		std::deque<CToken>::iterator expectedToken1 = tokens1.begin(); expectedToken1++; expectedToken1++;
		std::deque<CToken>::iterator currentToken2 = tokens1.begin();
		std::deque<CToken>::iterator expectedToken2 = tokens1.begin();
		WILDTest( "Seeing if we can match tokens.", CTokenizer::NextTokensAreIdentifiers( "test1", currentToken1, tokens1, EOnIdentifier, EAnswerIdentifier, ELastIdentifier_Sentinel ), true );
		WILDTest( "Verifying the current token was advanced correctly on match.", currentToken1, expectedToken1 );
		
		WILDTest( "Seeing if we can fail to match tokens.", CTokenizer::NextTokensAreIdentifiers( "test2", currentToken2, tokens1, EOnIdentifier, EStackIdentifier, ELastIdentifier_Sentinel ), false );
		WILDTest( "Verifying the current token was not advanced on mismatch.", currentToken2, expectedToken2 );
	}
	
	#if FIXING_TESTS
	return 0;
	#else
    return (int)sFailed;
	#endif
}

