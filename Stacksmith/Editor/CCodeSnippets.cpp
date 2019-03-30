//
//  CCodeSnippets.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 18/02/2017.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CCodeSnippets.h"


using namespace Carlson;

void	CCodeSnippets::AddSectionsAndBlocksFromHandlerList( const std::vector<CAddHandlerListEntry>& inHandlerList )
{
	CCodeSnippetsSection* currSection = nullptr;
	
	for( const CAddHandlerListEntry& handlerEntry : inHandlerList )
	{
		if( handlerEntry.mType == EHandlerEntryGroupHeader )
		{
			CCodeSnippetsSection newSection;
			newSection.SetName( handlerEntry.mHandlerName );
			currSection = AddSection( newSection );
		}
		else if( currSection )
		{
			CCodeSnippetsBlockEntry newEntry;
			newEntry.mHandlerEntry = handlerEntry;
			newEntry.SetName( handlerEntry.mHandlerName );
			currSection->AddBlockEntry( newEntry );
		}
	}
}
