//
//  CUndoStack.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-03-19.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

/*! @class CUndoStack
	Platform-agnostic wrapper class to permit registration of undo steps for user operations.
	This should wrap around any system-provided undo support and just hook our actions into
	it. As such, an instance of this is usually created by platform-specific code to reference
	the appropriate system object and then handed off to the objects that need to know about
	it. */

#ifndef __Stacksmith__CUndoStack__
#define __Stacksmith__CUndoStack__

#include <functional>
#include <string>


#if __OBJC__
@class NSUndoManager;
#else
struct NSUndoManager;
#endif


namespace Carlson
{

class CUndoStack
{
public:
	explicit CUndoStack( NSUndoManager* undoManager );	// Mac-specific.
	~CUndoStack();
	
	void	AddUndoAction( std::string inActionName, std::function<void()> inAction );
	
protected:
	NSUndoManager*	mUndoManager;		// Mac-specific.
};

}

#endif /* defined(__Stacksmith__CUndoStack__) */
