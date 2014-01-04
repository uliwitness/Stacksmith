//
//  CVisiblePart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	Base class for all parts that are real visible objects on screen,
	as opposed to e.g. timers, which are only visible during editing.
	Provides default code for reading/writing a few more properties
	shared by all these "visible" objects.
*/

#ifndef __Stacksmith__CVisiblePart__
#define __Stacksmith__CVisiblePart__

#include "CPart.h"


namespace Calhoun {

enum
{
	EPartTextAlignDefault = 0,	// "natural" text alignment. Whatever the user expects from the OS.
	EPartTextAlignLeft,
	EPartTextAlignCenter,
	EPartTextAlignRight,
	EPartTextAlignJustified,
	EPartTextAlign_Last			// Must be last, so we can use it as a loop limit.
};
typedef unsigned	TPartTextAlign;


enum
{
	EPartTextStyleBoldBit		= 0,
	EPartTextStyleItalicBit,
	EPartTextStyleUnderlineBit,
	EPartTextStyleOutlineBit,
	EPartTextStyleShadowBit,
	EPartTextStyleCondensedBit,
	EPartTextStyleExtendedBit,
	EPartTextStyleBit_Last	// The next bit after the last one used, used as a loop limit.
};


enum
{
	EPartTextStylePlain		= 0,
	EPartTextStyleBold		= (1 << EPartTextStyleBoldBit),
	EPartTextStyleItalic	= (1 << EPartTextStyleItalicBit),
	EPartTextStyleUnderline	= (1 << EPartTextStyleUnderlineBit),
	EPartTextStyleOutline	= (1 << EPartTextStyleOutlineBit),
	EPartTextStyleShadow	= (1 << EPartTextStyleShadowBit),
	EPartTextStyleCondensed	= (1 << EPartTextStyleCondensedBit),
	EPartTextStyleExtended	= (1 << EPartTextStyleExtendedBit),
	EPartTextStyle_Last		= (1 << EPartTextStyleBit_Last)	// The next bit after the last one used, used as a loop limit.
};
typedef unsigned	TPartTextStyle;	// Bit field of above constants.


class CVisiblePart : public CPart
{
public:
	CVisiblePart( CLayer * inOwner ) : CPart(inOwner) {};
	
	static TPartTextAlign	GetTextAlignFromString( const char* inString );
	static TPartTextStyle	GetStyleFromString( const char* inString );
	
	virtual void			SetFillColor( int red, int green, int blue, int alpha )	{ mFillColorRed = red; mFillColorGreen = green; mFillColorBlue = blue; mFillColorAlpha = alpha; };
	virtual void			SetBevelWidth( int bevel )		{ mBevelWidth = bevel; };
	virtual void			SetVisible( bool visible )		{ mVisible = visible; };
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	
	virtual void			DumpProperties( size_t inIndent );

protected:
	bool			mVisible;
	bool			mEnabled;
	int				mFillColorRed;
	int				mFillColorGreen;
	int				mFillColorBlue;
	int				mFillColorAlpha;
	int				mLineColorRed;
	int				mLineColorGreen;
	int				mLineColorBlue;
	int				mLineColorAlpha;
	int				mShadowColorRed;
	int				mShadowColorGreen;
	int				mShadowColorBlue;
	int				mShadowColorAlpha;
	double			mShadowOffsetWidth;
	double			mShadowOffsetHeight;
	double			mShadowBlurRadius;
	int				mLineWidth;
	int				mBevelWidth;
	int				mBevelAngle;
};

}

#endif /* defined(__Stacksmith__CVisiblePart__) */
