//
//  CPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 30.12.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CPart__
#define __Stacksmith__CPart__

#include "CConcreteObject.h"
#include "tinyxml2.h"
#include "CObjectID.h"


namespace Carlson {

class CLayer;
class CPart;
class CPartContents;


class CPartCreatorBase
{
public:
	CPartCreatorBase( const std::string inTypeString = std::string() ) : mPartTypeName(inTypeString) {};
	virtual ~CPartCreatorBase() {};
	
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ return NULL; };
	
	std::string			GetPartTypeName()	{ return mPartTypeName; };
	
protected:
	std::string		mPartTypeName;
};

template<class T>
class CPartCreator : public CPartCreatorBase
{
public:
	CPartCreator( const std::string inTypeString = std::string() ) : CPartCreatorBase(inTypeString) {};
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ return new T( inOwner ); };
};



class CPart : public CConcreteObject
{
public:
	static CPart*				NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner );
	static void					RegisterPartCreator( CPartCreatorBase* inCreator );
	static CPartCreatorBase*	GetPartCreatorForType( const char* inType );
	
	explicit CPart( CLayer *inOwner );
	
	virtual void				LoadFromElement( tinyxml2::XMLElement * inElement );
	
	ObjectID				GetID()			{ return mID; };
	int							GetFamily()		{ return mFamily; };
	virtual void				SetRect( int left, int top, int right, int bottom )	{ mLeft = left; mTop = top; mRight = right; mBottom = bottom; };
	int							GetLeft()		{ return mLeft; };
	int							GetTop()		{ return mTop; };
	int							GetRight()		{ return mRight; };
	int							GetBottom()		{ return mBottom; };
	virtual void				SetPartType( CPartCreatorBase* inType )	{ mPartType = inType; };
	virtual CPartCreatorBase*	GetPartType()							{ return mPartType; };

	virtual void				WakeUp()		{};
	virtual void				GoToSleep()		{};
	virtual void				SetPeeking( bool inState )				{};
	virtual CScriptableObject*	GetParentObject();
	virtual CStack*				GetStack();
	virtual CPartContents*		GetContentsOnCurrentCard();
	
	virtual bool				GetSharedText()				{ return true; };	// By default, background part contents are the same on all cards of that background.
	
	virtual void				Dump( size_t inIndent = 0 );
	
protected:
	virtual void				LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual const char*			GetIdentityForDump()					{ return "Part"; };
	virtual void				DumpProperties( size_t inIndent );

	int					mFamily;
	ObjectID		mID;
	int					mLeft;
	int					mTop;
	int					mRight;
	int					mBottom;
	CLayer	*			mOwner;		// Card/background we are on.
	CPartCreatorBase*	mPartType;	// Only used for comparing if two parts are same type.
};


typedef CRefCountedObjectRef<CPart>		CPartRef;

}

#endif /* defined(__Stacksmith__CPart__) */
