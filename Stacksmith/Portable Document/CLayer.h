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
	CLayer( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : mURL(inURL), mLoaded(false), mStack(inStack), mID(inID), mFileName(inFileName), mChangeCount(0) { mName = inName; };
	~CLayer();
	
	ObjectID		GetID()	const			{ return mID; };
	std::string		GetFileName() const		{ return mFileName; };
	
	virtual void	Load( std::function<void(CLayer*)> completionBlock );
	virtual bool	Save( const std::string& inPackagePath );
	
	bool			IsLoaded()					{ return mLoaded; };
	virtual void	SetLoaded( bool n )			{ mLoaded = true; };	// For marking a newly created never-before-saved card/bg in RAM as not needing to be loaded.
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
	virtual ObjectID	GetUniqueIDForPart();
	std::string		GetPictureURL();
	std::string		GetPictureName()		{ return mPictureName; };
	bool			GetShowPicture()		{ return mShowPict; };
	virtual void	SetName( const std::string& inName );
	void			UnhighlightFamilyMembersOfPart( CPart* inPart );	// inPart will not be unhighlighted, only everyone from the same family.
	
	CPartContents*	GetPartContentsByID( ObjectID inID, bool isForBackgroundPart );
	void			AddPartContents( CPartContents* inContents );
	
	virtual CStack*	GetStack()			{ return mStack; };
	const CStyleSheet&	GetStyles()		{ return mStyles; };

	virtual void					SetPeeking( bool inState );
	virtual void					DeleteSelectedItem();
	virtual bool					CanDeleteSelectedItem();
	virtual std::string				CopySelectedItem();
	virtual bool					CanCopySelectedItem();
	virtual std::vector<CPartRef>	PasteObject( const std::string& inXMLStr );

	virtual void	WakeUp();
	virtual void	GoToSleep();

	virtual bool	GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool	SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual bool	GetCantDelete()				{ return mCantDelete; };
	virtual void	SetCantDelete( bool n )		{ mCantDelete = n; };
	virtual bool	GetDontSearch()				{ return mDontSearch; };
	virtual void	SetDontSearch( bool n )		{ mDontSearch = n; };
	virtual bool	GetShowPict()				{ return mShowPict; };
	virtual void	SetShowPict( bool n )		{ mShowPict = n; };
	
	virtual void	IncrementChangeCount()		{ mChangeCount++; };
	virtual bool	GetNeedsToBeSaved()			{ return mChangeCount != 0; };
	
	virtual void	CorrectRectOfPart( CPart* inMovedPart, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock );	// addGuidelineBlock gets called to create guidelines.
	void			CorrectRectOfPart( CPart* inMovedPart, std::vector<CPartRef> inEligibleParts, THitPart partsToCorrect, long long *ioLeft, long long *ioTop, long long *ioRight, long long *ioBottom, std::function<void(long long inGuidelineCoord,TGuidelineCallbackAction action)> addGuidelineBlock );
	
	void			AddPartsToList( std::vector<CPartRef>& ioList )	{ ioList.insert( ioList.end(), mParts.begin(), mParts.end() ); };
	
	virtual void	Dump( size_t inIndent = 0 );
	
	virtual const char*	GetIdentityForDump();	// Called by "Dump" for the name of the class.
	
protected:
	virtual void	LoadPropertiesFromElement( tinyxml2::XMLElement* root );
	void			LoadAddColorPartsFromElement( tinyxml2::XMLElement* root );
	virtual const char*	GetLayerXMLType();
	virtual void	SavePropertiesToElement( tinyxml2::XMLElement* stackfile );
	virtual void	DumpProperties( size_t inIndent );
	virtual void	CallAllCompletionBlocks();
	virtual void	LoadPastedPartContents( CPart* newPart, ObjectID oldID, tinyxml2::XMLElement* *currCardContents, tinyxml2::XMLElement* *currBgContents, CStyleSheet * inStyleSheet );
	virtual void	LoadPastedPartBackgroundContents( CPart* newPart, tinyxml2::XMLElement* currBgContents, bool haveCardContents, CStyleSheet * inStyleSheet );
	virtual void	LoadPastedPartCardContents( CPart* newPart, tinyxml2::XMLElement* currCardContents, bool haveBgContents, CStyleSheet * inStyleSheet );

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
	
	ObjectID						mPartIDSeed;
	size_t							mChangeCount;
};

typedef CRefCountedObjectRef<CLayer>	CLayerRef;

}

#endif /* defined(__Stacksmith__CLayer__) */
