//
//  CRefCountedObject.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CRefCountedObject__
#define __Stacksmith__CRefCountedObject__

#include <cstddef>


class CRefCountedObject
{
public:
	CRefCountedObject() : mRefCount(1) {};
	
	virtual CRefCountedObject*	Retain()		{ mRefCount++; return this; };
	virtual void				Release()		{ if( (--mRefCount) == 0 ) delete this; };

protected:
	virtual ~CRefCountedObject() {};

	size_t		mRefCount;
};


template<class T>
class CRefCountedObjectRef
{
public:
	CRefCountedObjectRef( T* inObject = NULL, bool inTakeOverOwnership = false ) : mObject(inObject) { if( mObject && !inTakeOverOwnership ) mObject->Retain(); };
	CRefCountedObjectRef( const CRefCountedObjectRef<T>& inObjectRef ) { mObject = inObjectRef.mObject; mObject->Retain(); };
	~CRefCountedObjectRef() { mObject->Release(); mObject = NULL; };
	
	virtual T&			operator *()		{ return *mObject; };
	virtual T&			operator ->()		{ return *mObject; };
	virtual				operator T*()		{ return mObject; };
	
protected:
	T*	mObject;
};

#endif /* defined(__Stacksmith__CRefCountedObject__) */
