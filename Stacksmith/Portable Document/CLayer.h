//
//  CLayer.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CLayer__
#define __Stacksmith__CLayer__

#include "CConcreteObject.h"
#include "WILDObjectID.h"
#include "CPart.h"
#include "CPartContents.h"
#include <string>
#include <vector>
#include <map>


namespace Carlson {

class CStack;


class CLayer : public CConcreteObject
{
public:
	CLayer( std::string inURL, WILDObjectID inID, const std::string inName, CStack* inStack ) : mURL(inURL), mLoaded(false), mStack(inStack), mID(inID) { mName = inName; };
	~CLayer();
	
	WILDObjectID	GetID()	const	{ return mID; };
	
	virtual void	Load( std::function<void(CLayer*)> completionBlock );
	bool			IsLoaded()	{ return mLoaded; };
	virtual void	SetStack( CStack* inStack );
	size_t			GetNumParts()				{ return GetPartCountOfType( NULL ); };
	CPart*			GetPart( size_t inIndex )	{ return GetPartOfType(inIndex,NULL); };
	virtual size_t	GetPartCountOfType( CPartCreatorBase* inType );
	virtual CPart*	GetPartOfType( size_t inIndex, CPartCreatorBase* inType );
	virtual CPart*	GetPartWithNameOfType( const std::string& inName, CPartCreatorBase* inType );
	virtual CPart*	GetPartWithID( WILDObjectID inID );
	virtual void    AddPart( CPart* inPart );
	std::string		GetPictureURL();
	std::string		GetPictureName()		{ return mPictureName; };
	bool			GetShowPicture()		{ return mShowPict; };
	
	CPartContents*	GetPartContentsByID( WILDObjectID inID, bool isForBackgroundPart );

	virtual CStack*	GetStack()			{ return mStack; };

	virtual void	SetPeeking( bool inState );

	virtual void	WakeUp();
	virtual void	GoToSleep();
	
	virtual void	Dump( size_t inIndent = 0 );
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root );
	void			LoadAddColorPartsFromElement( tinyxml2::XMLElement* root );
	virtual void	DumpProperties( size_t inIndent );
	virtual void	CallAllCompletionBlocks();
	
	virtual const char*	GetIdentityForDump();	// Called by "Dump" for the name of the class.

	WILDObjectID					mID;
	std::string						mURL;
	bool							mLoaded;
	bool							mLoading;
	std::vector<std::function<void(CLayer*)>>	mLoadCompletionBlocks;
	bool							mShowPict;			// Should we draw mPicture or not?
	bool							mDontSearch;		// Do not include this card in searches.
	bool							mCantDelete;		// Prevent scripts from deleting this card?
	std::string						mPictureName;		// Card/background picture's file name.
	std::vector<CPartRef>			mParts;				// Array of parts on this card/bg.
	std::vector<CPartRef>			mAddColorParts;		// Array of parts for which we have AddColor color information. May contain parts that are already in mParts.
	std::vector<CPartContentsRef>	mContents;			// Dictionary of part ID -> contents mappings
	std::multimap<int,CPartRef>		mButtonFamilies;	// Family ID as key, and arrays of button parts belonging to these families.
	CStack	*						mStack;
};

typedef CRefCountedObjectRef<CLayer>	CLayerRef;

}

#endif /* defined(__Stacksmith__CLayer__) */
