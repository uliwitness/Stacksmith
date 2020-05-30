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
#include "CCanvas.h"


namespace Carlson {

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
	EPartTextStyleGroupBit,
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
	EPartTextStyleGroup		= (1 << EPartTextStyleGroupBit),
	EPartTextStyle_Last		= (1 << EPartTextStyleBit_Last)	// The next bit after the last one used, used as a loop limit.
};
typedef unsigned	TPartTextStyle;	// Bit field of above constants.


class CVisiblePart : public CPart
{
public:
	CVisiblePart( CLayer * inOwner ) : CPart(inOwner), mVisible(true), mEnabled(true), mFillColorRed(65535), mFillColorGreen(65535), mFillColorBlue(65535), mFillColorAlpha(65535), mLineColorRed(0), mLineColorGreen(0), mLineColorBlue(0), mLineColorAlpha(65535), mShadowColorRed(0), mShadowColorGreen(0), mShadowColorBlue(0), mShadowColorAlpha(0), mShadowOffsetWidth(0), mShadowOffsetHeight(0), mShadowBlurRadius(0), mTextColorRed(-1), mTextColorGreen(-1), mTextColorBlue(-1), mTextColorAlpha(-1), mLineWidth(1), mBevelWidth(0), mBevelAngle(0) {};
	
	static TPartTextAlign	GetTextAlignFromString( const char* inString );
	static const char*		GetStringFromTextAlign( TPartTextAlign inAlign );
	static TPartTextStyle	GetStyleFromString( const char* inString );
	static std::vector<const char*>		GetStringsForStyle( TPartTextStyle inStyle );
	
	virtual void			SetVisible( bool visible )		{ mVisible = visible; IncrementChangeCount(); };
	bool					GetVisible()					{ return mVisible; };
	virtual void			SetEnabled( bool n )			{ mEnabled = n; IncrementChangeCount(); };
	bool					GetEnabled()					{ return mEnabled; };
	virtual void			SetFillColor( int r, int g, int b, int a )	{ mFillColorRed = r; mFillColorGreen = g; mFillColorBlue = b; mFillColorAlpha = a; IncrementChangeCount(); };
	int						GetFillColorRed()				{ return mFillColorRed; };
	int						GetFillColorGreen()				{ return mFillColorGreen; };
	int						GetFillColorBlue()				{ return mFillColorBlue; };
	int						GetFillColorAlpha()				{ return mFillColorAlpha; };
	virtual void			SetLineColor( int r, int g, int b, int a )	{ mLineColorRed = r; mLineColorGreen = g; mLineColorBlue = b; mLineColorAlpha = a; IncrementChangeCount(); };
	int						GetLineColorRed()				{ return mLineColorRed; };
	int						GetLineColorGreen()				{ return mLineColorGreen; };
	int						GetLineColorBlue()				{ return mLineColorBlue; };
	int						GetLineColorAlpha()				{ return mLineColorAlpha; };
	virtual void			SetShadowColor( int r, int g, int b, int a )	{ mShadowColorRed = r; mShadowColorGreen = g; mShadowColorBlue = b; mShadowColorAlpha = a; IncrementChangeCount(); };
	int						GetShadowColorRed()				{ return mShadowColorRed; };
	int						GetShadowColorGreen()			{ return mShadowColorGreen; };
	int						GetShadowColorBlue()			{ return mShadowColorBlue; };
	int						GetShadowColorAlpha()			{ return mShadowColorAlpha; };
	int						GetTextColorRed()				{ return mTextColorRed; };
	int						GetTextColorGreen()				{ return mTextColorGreen; };
	int						GetTextColorBlue()				{ return mTextColorBlue; };
	int						GetTextColorAlpha()				{ return mTextColorAlpha; };
	virtual void			SetShadowOffset( double w, double h )	{ mShadowOffsetWidth = w; mShadowOffsetHeight = h; IncrementChangeCount(); };
	double					GetShadowOffsetWidth()			{ return mShadowOffsetWidth; };
	double					GetShadowOffsetHeight()			{ return mShadowOffsetHeight; };
	virtual void			SetShadowBlurRadius( double r )	{ mShadowBlurRadius = r; IncrementChangeCount(); };
	double					GetShadowBlurRadius()			{ return mShadowBlurRadius; };
	virtual void			SetLineWidth( int w )			{ mLineWidth = w; IncrementChangeCount(); };
	int						GetLineWidth()					{ return mLineWidth; };
	virtual void			SetBevelWidth( int bevel )		{ mBevelWidth = bevel; IncrementChangeCount(); };
	int						GetBevelWidth()					{ return mBevelWidth; };
	virtual void			SetBevelAngle( int a )			{ mBevelAngle = a; IncrementChangeCount(); };
	int						GetBevelAngle()					{ return mBevelAngle; };
	std::vector<CColor>		GetGradientColors()	const		{ return mGradientColors; }
	
	virtual void			SetToolTip( const std::string& inToolTip )	{ mToolTip = inToolTip; IncrementChangeCount(); };
	virtual std::string		GetToolTip()								{ return mToolTip; };
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );

	virtual std::string		GetTextFont()								{ return ""; };
	virtual int				GetTextSize()								{ return -1; };
	virtual TPartTextStyle	GetTextStyle()								{ return EPartTextStyle_Last; };
	virtual TPartTextAlign	GetTextAlign()								{ return EPartTextAlign_Last; };
	virtual void			SetTextFont( std::string f )				{};
	virtual void			SetTextSize( int s )						{};
	virtual void			SetTextStyle( TPartTextStyle s )			{};
	virtual void			SetTextAlign( TPartTextAlign a )			{};
	virtual void			SetTextColor( int r, int g, int b, int a )	{ mTextColorRed = r; mTextColorGreen = g; mTextColorBlue = b; mTextColorAlpha = a; };
	
	virtual THitPart		HitTestForEditing( LEONumber x, LEONumber y, THitTestHandlesFlag handlesToo, LEOInteger *outCustomHandleIndex );
	virtual bool			IsSelected()					{ if( !GetVisible() ) return false; return CPart::IsSelected(); };

	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElement( tinyxml2::XMLElement * inElement );
	
	static bool				GetColorFromValue( LEOValuePtr inValue, LEOContext* inContext, int* outRed, int* outGreen, int* outBlue, int* outAlpha );
	static bool				GetSizeFromValue( LEOValuePtr inValue, LEOContext* inContext, double* outWidth, double* outHeight );
	
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
	int				mTextColorRed;
	int				mTextColorGreen;
	int				mTextColorBlue;
	int				mTextColorAlpha;
	int				mLineWidth;
	int				mBevelWidth;
	int				mBevelAngle;
	std::vector<CColor> mGradientColors;
	std::string		mToolTip;
};

}

#endif /* defined(__Stacksmith__CVisiblePart__) */
