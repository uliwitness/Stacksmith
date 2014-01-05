//
//  CCancelPolling.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CCancelPolling.h"
#import <Carbon/Carbon.h>


using namespace Calhoun;


bool	CCancelPolling::GetUserWantsToCancel()
{
	KeyMap		keyStates;
	KeyMap		desiredKeyStates = { {0x00000000}, {0x00808000}, {0x00000000}, {0x00000000} };
	GetKeys( keyStates );
	if( keyStates[0].bigEndianValue == desiredKeyStates[0].bigEndianValue
		&& keyStates[1].bigEndianValue == desiredKeyStates[1].bigEndianValue
		&& keyStates[2].bigEndianValue == desiredKeyStates[2].bigEndianValue
		&& keyStates[3].bigEndianValue == desiredKeyStates[3].bigEndianValue )
	{
		return true;
	}
	return false;
}