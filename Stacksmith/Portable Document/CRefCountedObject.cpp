//
//  CRefCountedObject.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CRefCountedObject.h"


using namespace Calhoun;


static CAutoreleasePool		*sCurrentPool = NULL;


CRefCountedObject*	CRefCountedObject::Autorelease()
{
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


