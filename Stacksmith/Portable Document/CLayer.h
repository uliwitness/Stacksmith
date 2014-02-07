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
#include "CObjectID.h"
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
	CLayer( std::string inURL, ObjectID inID, const std::string inName, const std::string& inFileName, CStack* inStack ) : mURL(inURL), mLoaded(false), mStack(inStack), mID(inID), mFileName(inFileName) { mName = inName; };
	~CLayer();
	
	ObjectID		GetID()	const			{ return mID; };
	std::string		GetFileName() const		{ return mFileName; };
	
	virtual void	Load( std::function<void(CLayer*)> completionBlock );
	virtual void	Save( const std::string& inPackagePath );
	
	bool			IsLoaded()	{ return mLoaded; };
	virtual void	SetStack( CStack* inStack );
	size_t			GetNumParts()				{ return GetPartCountOfType( NULL ); };
	CPart*			GetPart( size_t inIndex )	{ return GetPartOfType(inIndex,NULL); };
	virtual size_t	GetPartCountOfType( CPartCreatorBase* inType );
	virtual CPart*	GetPartOfType( size_t inIndex, CPartCreatorBase* inType );
	virtual CPart*	GetPartWithNameOfType( const std::string& inName, CPartCreatorBase* inType );
	virtual CPart*	GetPartWithID( ObjectID inID );
	virtual void    AddPart( CPart* inPart );
	virtual LEOInteger	GetIndexOfPart( CPart* inPart, CPartCreatorBase* inType );
	virtual void	SetIndexOfPart( CPart* inPart, LEOInteger inIndex, CPartCreatorBase* inType );
	std::string		GetPictureURL();
	std::string		GetPictureName()		{ return mPictureName; };
	bool			GetShowPicture()		{ return mShowPict; };
	void			UnhighlightFamilyMembersOfPart( CPart* inPart );	// inPart will not be unhighlighted, only everyone from the same family.
	
	CPartContents*	GetPartContentsByID( ObjectID inID, bool isForBackgroundPart );
	void			AddPartContents( CPartContents* inContents );

	virtual CStack*	GetStack()			{ return mStack; };
	const CStyleSheet&	GetStyles()		{ return mStyles; };

	virtual void	SetPeeking( bool inState );

	virtual void	WakeUp();
	virtual void	GoToSleep();

	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual void	Dump( size_t inIndent = 0 );
	
	virtual const char*	GetIdentityForDump();	// Called by "Dump" for the name of the class.
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root );
	void			LoadAddColorPartsFromElement( tinyxml2::XMLElement* root );
	virtual const char*	GetLayerXMLType();
	virtual void	SavePropertiesToElementOfDocument( tinyxml2::XMLElement* stackfile, tinyxml2::XMLDocument* document );
	virtual void	DumpProperties( size_t inIndent );
	virtual void	CallAllCompletionBlocks();

	ObjectID						mID;
	std::string						mURL;
	std::string						mFileName;
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
	CStyleSheet						mStyles;
	CStack	*						mStack;
};

typedef CRefCountedObjectRef<CLayer>	CLayerRef;

}

#endif /* defined(__Stacksmith__CLayer__) */
