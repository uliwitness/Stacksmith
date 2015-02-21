//
//  CRefCountedObject.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CRefCountedObject.h"
#include <map>
#include <string>
#include <cassert>


using namespace Carlson;


static CAutoreleasePool		*sCurrentPool = NULL;


CRefCountedObject*	CRefCountedObject::Autorelease()
{
	assert(sCurrentPool != NULL);
	sCurrentPool->Autorelease(this);
	
	return this;
}


/* static */ const char*	CRefCountedObject::IndentString( size_t inIndentLevel )
{
	static char		sIndentChars[] = { '\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
										0 };
	if( inIndentLevel >= (sizeof(sIndentChars) -1) )
		return sIndentChars;
	
	return sIndentChars +(sizeof(sIndentChars) -1) -inIndentLevel;
}


/* static */ const char*	CRefCountedObject::DebugNameForPointer( void* inPtr )
{
	static const char*		sAvailableNames[] = {
													"Rebecca",
													"Tyler",
													"Ruth",
													"Mike",
													"Kristee",
													"Bill",
													"Marge",
													"Dan",
													"Sioux",
													"Ted",
													"Carol",
													"Adam",
													"Susan",
													"Mark",
													"Elaine",
													"Kevin",
													"Jane",
													"Martin",
													"Jody",
													"Steve",
													"Paula",
													"Ed",
													"Alexis",
													"David",
													"Katie",
													"Gary",
													"Fabrice",
													NULL
												};
	static int							sCurrNameIndex = 0;
	static std::map<void*,const char*>	sPointerNames;
	
	auto	foundPtrItty = sPointerNames.find(inPtr);
	if( foundPtrItty != sPointerNames.end() )
	{
		return foundPtrItty->second;
	}
	
	const char*	currName = NULL;
	if( sAvailableNames[sCurrNameIndex] == NULL )
	{
		currName = sAvailableNames[0];
		sPointerNames.insert( std::pair<void*,const char*>(inPtr,currName) );
		sCurrNameIndex = 1;
	}
	else
	{
		currName = sAvailableNames[sCurrNameIndex++];
		sPointerNames.insert( std::pair<void*,const char*>(inPtr,currName) );
	}
	
	return currName;
}


CAutoreleasePool::CAutoreleasePool()
{
	mPreviousPool = sCurrentPool;
	sCurrentPool = this;
}


void	CAutoreleasePool::Autorelease( CRefCountedObject* inObject )
{
	mObjects.push_back( inObject );
}


CAutoreleasePool::~CAutoreleasePool()
{
	sCurrentPool = mPreviousPool;
	
	for( auto itty = mObjects.begin(); itty != mObjects.end(); itty++ )
		(*itty)->Release();
}


