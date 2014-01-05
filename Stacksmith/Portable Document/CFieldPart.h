//
//  CFieldPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CFieldPart__
#define __Stacksmith__CFieldPart__

#include "CVisiblePart.h"

namespace Carlson {

class CFieldPart : public CVisiblePart
{
public:
	explicit CFieldPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual const char*		GetIdentityForDump()	{ return "Field"; };
	virtual void			DumpProperties( size_t inIndent );
	
protected:
	bool			mDontWrap;
	bool			mDontSearch;
	bool			mSharedText;
	bool			mFixedLineHeight;
	bool			mAutoTab;
	bool			mLockText;
	bool			mAutoSelect;
	bool			mMultipleLines;
	bool			mShowLines;
	bool			mWideMargins;
	TPartTextAlign	mTextAlign;
	std::string		mFont;
	int				mTextSize;
	bool			mHasHorizontalScroller;
	bool			mHasVerticalScroller;
};

}

#endif /* defined(__Stacksmith__CFieldPart__) */
