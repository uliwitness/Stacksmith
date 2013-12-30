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
#include <string>
#include <vector>
#include <map>


class CPart;
class CPartContents;


class CLayer : public CConcreteObject
{
public:
	CLayer( std::string inURL ) : mURL(inURL), mLoaded(false) {};
	~CLayer();
	
	virtual void	Load( std::function<void(CLayer*)> completionBlock );
	bool			IsLoaded()	{ return mLoaded; };
	
protected:
	WILDObjectID				mID;
	std::string					mURL;
	bool						mLoaded;
	bool						mLoading;
	std::vector<std::function<void(CLayer*)>>	mLoadCompletionBlocks;
	bool						mShowPict;			// Should we draw mPicture or not?
	bool						mDontSearch;		// Do not include this card in searches.
	bool						mCantDelete;		// Prevent scripts from deleting this card?
	std::string					mPictureName;		// Card/background picture's file name.
	std::vector<CPart*>			mParts;				// Array of parts on this card/bg.
	std::vector<CPart*>			mAddColorParts;		// Array of parts for which we have AddColor color information. May contain parts that are already in mParts.
	std::vector<CPartContents*>	mContents;			// Dictionary of part ID -> contents mappings
	std::multimap<int,CPart*>	mButtonFamilies;	// Family ID as key, and arrays of button parts belonging to these families.
};

typedef CRefCountedObjectRef<CLayer>	CLayerRef;

#endif /* defined(__Stacksmith__CLayer__) */
