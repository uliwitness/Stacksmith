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
#include "WILDObjectID.h"


namespace Calhoun {

class CLayer;
class CPart;


class CPartCreatorBase
{
public:
	virtual ~CPartCreatorBase() {};
	
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ return NULL; };
};

template<class T>
class CPartCreator : public CPartCreatorBase
{
	virtual CPart	*	NewPartInOwner( CLayer *inOwner )	{ return new T( inOwner ); };
};



class CPart : public CConcreteObject
{
public:
	static CPart*	NewPartWithElement( tinyxml2::XMLElement * inElement, CLayer *inOwner );
	static void		RegisterPartCreator( const std::string inTypeString, CPartCreatorBase* inCreator );
	
	explicit CPart( CLayer *inOwner );
	
	virtual void			LoadFromElement( tinyxml2::XMLElement * inElement );
	
	int						GetFamily()		{ return mFamily; };
	
	virtual void			Dump( size_t inIndent = 0 );
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual const char*		GetIdentityForDump()	{ return "Part"; };
	virtual void			DumpProperties( size_t inIndent );

	int				mFamily;
	WILDObjectID	mID;
	int				mLeft;
	int				mTop;
	int				mRight;
	int				mBottom;
	bool			mVisible;
	bool			mEnabled;
	CLayer	*		mOwner;		// Card/background we are on.
};


typedef CRefCountedObjectRef<CPart>		CPartRef;

}

#endif /* defined(__Stacksmith__CPart__) */
