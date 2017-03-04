//
//  CVariableWatcher.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CVariableWatcher__
#define __Stacksmith__CVariableWatcher__

#include "CScriptableObjectValue.h"
#include "CTimer.h"
#include "LEOHandlerID.h"


namespace Carlson {


struct CVariableWatcherEntry
{
	std::string		mUserVariableName;
	std::string		mValue;
};


class CVariableWatcher : public CScriptableObject
{
public:
	static void			SetSharedInstance( CVariableWatcher* inMsg );	// Call once at startup
	static CVariableWatcher*	GetSharedInstance();
	
	CVariableWatcher() : mVariableUpdateTimer(30,[this](CTimer*sender){ UpdateVariables(); }) {};
	
	size_t				GetNumVariables()							{ return mVariables.size(); };
	void				GetVariableAtIndex( size_t inIndex, std::string& outUserVarName, std::string& outValue ) const;
	// We don't provide InitValue here because the variable watcher can be referenced from many context groups.
	
	virtual void		SetVisible( bool n );
	virtual bool		IsVisible()									{ return false; };
	
protected:
	virtual void		UpdateVariables();	// Subclassers should override this, call super, then update their UI.
	void				UpdateOneVariable( LEOArrayEntry * currEntry );
	
	std::vector<CVariableWatcherEntry>	mVariables;
	CTimer								mVariableUpdateTimer;
};


}

#endif /* defined(__Stacksmith__CVariableWatcher__) */
