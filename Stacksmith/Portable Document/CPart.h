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
	virtual void				SaveToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument* document );
	
	ObjectID					GetID()			{ return mID; };
	LEOInteger					GetFamily()		{ return mFamily; };
	virtual void				SetFamily( LEOInteger inFamily )					{ mFamily = inFamily; };
	virtual void				SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )	{ mLeft = left; mTop = top; mRight = right; mBottom = bottom; };
	LEOInteger					GetLeft()		{ return mLeft; };
	LEOInteger					GetTop()		{ return mTop; };
	LEOInteger					GetRight()		{ return mRight; };
	LEOInteger					GetBottom()		{ return mBottom; };
	virtual void				SetPartType( CPartCreatorBase* inType )	{ mPartType = inType; };	// Remembers the type, can't possibly change the type of this class.
	virtual CPartCreatorBase*	GetPartType()							{ return mPartType; };
	virtual LEOInteger			GetIndex( CPartCreatorBase* inType = NULL );
	virtual void				SetIndex( LEOInteger inIndex, CPartCreatorBase* inType = NULL );
	
	virtual bool				GetTextContents( std::string& outString );
	virtual bool				SetTextContents( std::string inString);

	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual void				WakeUp()		{};
	virtual void				GoToSleep()		{};
	virtual void				SetPeeking( bool inState )				{};
	virtual CScriptableObject*	GetParentObject();
	virtual CStack*				GetStack();
	virtual CPartContents*		GetContentsOnCurrentCard();
	
	virtual bool				GetSharedText()					{ return true; };	// By default, background part contents are the same on all cards of that background.
	virtual void				SetSelected( bool inSelected )	{ mSelected = inSelected; };
	virtual bool				IsSelected()					{ return mSelected; };
	
	virtual void				Dump( size_t inIndent = 0 );
	
protected:
	virtual void				LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual const char*			GetIdentityForDump()					{ return "Part"; };
	virtual void				DumpProperties( size_t inIndent );

	LEOInteger			mFamily;
	ObjectID			mID;
	LEOInteger			mLeft;
	LEOInteger			mTop;
	LEOInteger			mRight;
	LEOInteger			mBottom;
	CLayer	*			mOwner;		// Card/background we are on.
	CPartCreatorBase*	mPartType;	// Only used for comparing if two parts are same type.
	bool				mSelected;
};


typedef CRefCountedObjectRef<CPart>		CPartRef;

}

#endif /* defined(__Stacksmith__CPart__) */
