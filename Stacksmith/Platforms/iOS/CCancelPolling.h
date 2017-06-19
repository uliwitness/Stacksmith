//
//  CCancelPolling.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	On Mac, it is common to be able to cancel scripts by holding the command
	key down and pressing the period key. On Unix, you usually hold Ctrl and
	D to abort a shell script. This method is intended to let you poll such
	an external mechanism. It is called before every command is executed by
	the interpreter, and if it returns true, the script aborts quietly. If
	this doesn't make sense on your platform, just stub it to return false.
	Otherwise, query whatever mechanism makes sense for canceling script execution.
*/

#ifndef __Stacksmith__CCancelPolling__
#define __Stacksmith__CCancelPolling__

namespace Carlson
{

class CCancelPolling
{
public:
	static bool	GetUserWantsToCancel();
};

}

#endif /* defined(__Stacksmith__CCancelPolling__) */
