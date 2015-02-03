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
#include <vector>


namespace Carlson {

/*!
	Base class for reference-counted objects that stay around until the last
	owner releases them. After the object's been created, every other owner who
	wants to keep it around must call Retain() to get shared custody, and Release()
	when they're OK with it going away. If you need to return an object of this
	type and don't need to keep it around yourself, use Autorelease() to hand it
	over to the current CAutoreleasePool, which will release it if nobody retains
	it by the time it goes out of scope. Or use a CRefCountedObjectRef.
*/
class CRefCountedObject
{
public:
	CRefCountedObject() : mRefCount(1) {};
	
	virtual CRefCountedObject*	Retain()		{ mRefCount++; return this; };
	virtual void				Release()		{ if( (--mRefCount) == 0 ) delete this; };
	virtual CRefCountedObject*	Autorelease();
	
	virtual void				Dump( size_t inIndentLevel = 0 )	{ printf( "%s<Unknown Object>\n", IndentString(inIndentLevel) ); };
	
	static const char*			IndentString( size_t inIndentLevel );
	
protected:
	virtual ~CRefCountedObject() {};

	size_t		mRefCount;
};


/*!
	A smart pointer to a CRefCountedObject that retains/releases the object as needed.
*/

template<class T>
class CRefCountedObjectRef
{
public:
	CRefCountedObjectRef( T* inObject = NULL, bool inTakeOverOwnership = false ) : mObject(inObject) { if( mObject && !inTakeOverOwnership ) mObject->Retain(); };
	CRefCountedObjectRef( const CRefCountedObjectRef<T>& inObjectRef ) { mObject = inObjectRef.mObject; if( mObject ) mObject->Retain(); };
	virtual ~CRefCountedObjectRef() { if( mObject ) mObject->Release(); mObject = NULL; };
	
	virtual T&							operator *()				{ return *mObject; };
	virtual T*							operator ->()				{ return mObject; };
	virtual								operator T*()				{ return mObject; };
	virtual T&							operator *() const			{ return *mObject; };
	virtual T*							operator ->() const			{ return mObject; };
	virtual								operator T*() const			{ return mObject; };
	virtual	bool						operator <( const CRefCountedObjectRef<T>& inObject ) const	{ return mObject < inObject.mObject; };
	virtual	bool						operator >( const CRefCountedObjectRef<T>& inObject ) const	{ return mObject > inObject.mObject; };
	virtual	bool						operator ==( const CRefCountedObjectRef<T>& inObject ) const { return mObject == inObject.mObject; };
	virtual	bool						operator !=( const CRefCountedObjectRef<T>& inObject ) const { return mObject != inObject.mObject; };
	virtual	bool						operator <( T* inObject ) const	{ return mObject < inObject; };
	virtual	bool						operator >( T* inObject ) const	{ return mObject > inObject; };
	virtual	bool						operator ==( T* inObject ) const { return mObject == inObject; };
	virtual	bool						operator !=( T* inObject ) const { return mObject != inObject; };
	virtual	bool						operator !() const	{ return mObject == NULL; };
	virtual	CRefCountedObjectRef<T>&	operator =( T* inObject )	{ if( mObject != inObject ) { if( mObject ) mObject->Release(); if( inObject ) inObject->Retain(); mObject = inObject; } return *this; };
	virtual	CRefCountedObjectRef<T>&	operator =( const CRefCountedObjectRef<T>& inObject )	{ if( mObject != inObject.mObject ) { if( mObject ) mObject->Release(); if( inObject.mObject ) inObject.mObject->Retain(); mObject = inObject.mObject; } return *this; };
	
protected:
	T*	mObject;
};


/*!
	Stack object that holds on to any CRefCountedObjects that you call Autorelease() on.
	Whatever object you create last becomes the current pool that autoreleased objects will
	be attached to, until it goes out of scope, at which point in time the previous pool
	is made current again.
*/

class CAutoreleasePool
{
public:
	CAutoreleasePool();
	~CAutoreleasePool();
	
	void	Autorelease( CRefCountedObject* inObject );

protected:
	std::vector<CRefCountedObject*>		mObjects;
	CAutoreleasePool*					mPreviousPool;
};

}

#endif /* defined(__Stacksmith__CRefCountedObject__) */
