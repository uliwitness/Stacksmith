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
#include <set>

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
	explicit CButtonPart( CLayer *inOwner ) : CVisiblePart( inOwner ), mShowName(true), mHighlight(false), mAutoHighlight(true), mSharedHighlight(false), mHighlightForTracking(false), mTitleWidth(0), mIconID(0), mTextAlign(EPartTextAlignDefault), mTextSize(12), mTextStyle(EPartTextStylePlain), mButtonStyle(EButtonStyleRectangle) {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual bool			GetSharedText()			{ return true; };
	virtual bool			GetSharedHighlight()	{ return mSharedHighlight; };
	virtual void			SetSharedHighlight( bool inHighlight )	{ mSharedHighlight = inHighlight; IncrementChangeCount(); };
	virtual bool			GetAutoHighlight()						{ return mAutoHighlight; };
	virtual void			SetAutoHighlight( bool inHighlight )	{ mAutoHighlight = inHighlight; IncrementChangeCount(); };
	virtual bool			GetHighlight();
	virtual void			SetHighlight( bool inHighlight );
	virtual bool			GetShowName()							{ return mShowName; };
	virtual void			SetShowName( bool inShowName )			{ mShowName = inShowName; IncrementChangeCount(); };
	virtual void			SetHighlightForTracking( bool inState )	{ mHighlightForTracking = inState; IncrementChangeCount(); };
	
	virtual void			SetStyle( TButtonStyle s )			{ mButtonStyle = s; IncrementChangeCount(); };
	virtual TButtonStyle	GetStyle()							{ return mButtonStyle; };
	
	ObjectID				GetIconID()							{ return mIconID; };
	virtual void			SetIconID( ObjectID inID )			{ mIconID = inID; IncrementChangeCount(); };
	
	virtual void			PrepareMouseUp();
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument * inDocument );
	virtual void			ApplyChangedSelectedLinesToView()		{};
	
	virtual const char*		GetIdentityForDump()	{ return "Button"; };
	virtual void			DumpProperties( size_t inIndent );

	static TButtonStyle	GetButtonStyleFromString( const char* inStyleStr );

protected:
	bool				mShowName;
	bool				mHighlight;
	bool				mAutoHighlight;
	bool				mSharedHighlight;
	bool				mHighlightForTracking;
	int					mTitleWidth;
	ObjectID			mIconID;
	TPartTextAlign		mTextAlign;
	std::string			mFont;
	int					mTextSize;
	TPartTextStyle		mTextStyle;
	TButtonStyle		mButtonStyle;
	std::set<size_t>	mSelectedLines;
};

}

#endif /* defined(__Stacksmith__CButtonPart__) */
