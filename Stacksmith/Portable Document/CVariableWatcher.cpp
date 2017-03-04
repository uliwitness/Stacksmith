//
//  CVariableWatcher.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CVariableWatcher.h"
#include "Forge.h"
#include "CDocument.h"
#include "CAlert.h"
#include <sstream>


using namespace Carlson;


static CVariableWatcher*		sVariableWatcher = NULL;


void	CVariableWatcher::SetSharedInstance( CVariableWatcher* inMsg )
{
	sVariableWatcher = inMsg;
}


CVariableWatcher*	CVariableWatcher::GetSharedInstance()
{
	return sVariableWatcher;
}


void		CVariableWatcher::GetVariableAtIndex( size_t inIndex, std::string& outUserVarName, std::string& outValue ) const
{
	const CVariableWatcherEntry&	entry = mVariables[inIndex];
	outUserVarName = entry.mUserVariableName;
	outValue = entry.mValue;
}


void	CVariableWatcher::SetVisible( bool isVisible )
{
	if( isVisible )
		mVariableUpdateTimer.Start();
	else
		mVariableUpdateTimer.Stop();
}


void	CVariableWatcher::UpdateOneVariable( LEOArrayEntry * currEntry )
{
	char		strBuf[100];
	const char* theStr = LEOGetValueAsString( &currEntry->value, strBuf, sizeof(strBuf), nullptr );
	const CVariableWatcherEntry	entry = { currEntry->key, theStr };
	mVariables.push_back( entry );
	
	if( currEntry->smallerItem )
	{
		UpdateOneVariable( currEntry->smallerItem );
	}
	if( currEntry->largerItem )
	{
		UpdateOneVariable( currEntry->largerItem );
	}
}


void	CVariableWatcher::UpdateVariables()
{
	CDocument * theDocument = CDocumentManager::GetSharedDocumentManager()->GetFrontDocument();
	mVariables.clear();
	if( theDocument )
	{
		LEOContextGroup* theGroup = theDocument->GetScriptContextGroupObject();
		if( theGroup && theGroup->globals )
		{
			UpdateOneVariable( theGroup->globals );
			std::sort(mVariables.begin(),mVariables.end(),[]( const CVariableWatcherEntry a, const CVariableWatcherEntry b ){ return a.mUserVariableName.compare(b.mUserVariableName); });
		}
	}
}

