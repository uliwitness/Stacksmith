//
//  CButtonPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CButtonPart__
#define __Stacksmith__CButtonPart__

#include "CVisiblePart.h"

namespace Carlson {

typedef enum
{
	EButtonStyleTransparent,
	EButtonStyleOpaque,
	EButtonStyleRectangle,
	EButtonStyleShadow,
	EButtonStyleRoundrect,
	EButtonStyleCheckBox,
	EButtonStyleRadioButton,
	EButtonStyleStandard,
	EButtonStyleDefault,
	EButtonStylePopUp,
	EButtonStyleOval,
	EButtonStyle_Last
} TButtonStyle;


class CButtonPart : public CVisiblePart
{
public:
	explicit CButtonPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual bool			GetSharedText()			{ return mSharedHighlight; };
	
	virtual const char*		GetIdentityForDump()	{ return "Button"; };
	virtual void			DumpProperties( size_t inIndent );

	static TButtonStyle		GetButtonStyleFromString( const char* inStyleStr );

protected:
	bool			mShowName;
	bool			mHighlight;
	bool			mAutoHighlight;
	bool			mSharedHighlight;
	int				mTitleWidth;
	WILDObjectID	mIconID;
	TPartTextAlign	mTextAlign;
	std::string		mFont;
	int				mTextSize;
	TButtonStyle	mButtonStyle;
};

}

#endif /* defined(__Stacksmith__CButtonPart__) */
