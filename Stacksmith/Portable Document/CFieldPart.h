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


class CAttributedString;

typedef enum
{
	EFieldStyleTransparent,
	EFieldStyleOpaque,
	EFieldStyleRectangle,
	EFieldStyleShadow,
	EFieldStyleScrolling,
	EFieldStyleStandard,
	EFieldStylePopUp,
	EFieldStyle_Last
} TFieldStyle;


class CFieldPart : public CVisiblePart
{
public:
	explicit CFieldPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );

protected:
	~CFieldPart()	{};
	
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual bool			GetSharedText()					{ return mSharedText; };
	virtual void			SetSharedText( bool inST )		{ mSharedText = inST; };
	
	virtual bool			GetLockText()					{ return mLockText; };
	virtual void			SetLockText( bool inST )		{ mLockText = inST; };
	
	virtual bool			GetAutoSelect()					{ return mAutoSelect; };
	virtual void			SetAutoSelect( bool inST )		{ mAutoSelect = inST; };
	
	virtual void			TextStylesChanged()				{};
	
	virtual const char*		GetIdentityForDump()	{ return "Field"; };
	virtual void			DumpProperties( size_t inIndent );

	static void				ApplyStyleStringToRangeOfAttributedString( const char* currStyleName, size_t byteRangeStart, size_t byteRangeEnd, CAttributedString& attrStr );
	static TFieldStyle		GetFieldStyleFromString( const char* inStyleStr );
	
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
	TPartTextStyle	mTextStyle;
	TPartTextAlign	mTextAlign;
	std::string		mFont;
	int				mTextSize;
	bool			mHasHorizontalScroller;
	bool			mHasVerticalScroller;
	TFieldStyle		mFieldStyle;
};

}

#endif /* defined(__Stacksmith__CFieldPart__) */
