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
#include <set>

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
	EFieldStyleSearch,
	EFieldStyle_Last
} TFieldStyle;


typedef enum
{
	EColumnTypeText,
	EColumnTypeCheckbox,
	EColumnTypeIcon,
	EColumnType_Last
} TColumnType;


struct CColumnInfo
{
	TColumnType		mType;
	long long		mWidth;
	std::string		mName;
	bool			mEditable;
};


class CFieldPart : public CVisiblePart
{
public:
	explicit CFieldPart( CLayer *inOwner ) : CVisiblePart( inOwner ), mDontWrap(false), mDontSearch(false), mSharedText(false), mFixedLineHeight(false), mAutoTab(false), mLockText(false), mAutoSelect(false), mMultipleLines(false), mShowLines(false), mWideMargins(false), mTextStyle(EPartTextStylePlain), mTextAlign(EPartTextAlignDefault), mTextSize(12), mTextHeight(0), mHasHorizontalScroller(false), mHasVerticalScroller(false), mHasColumnHeaders(false), mNeedsToImportTextFromView(false), mFieldStyle(EFieldStyleStandard), mCursorID(128)	 {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual void			SetNeedsToImportTextFromView( bool inNeeded )	{ mNeedsToImportTextFromView = inNeeded;  };

	virtual bool			GetTextContents( std::string &outString );
	virtual bool			SetTextContents( const std::string &inString );

	virtual void			ClearSelectedLines()				{ mSelectedLines.clear(); IncrementChangeCount(); };
	virtual void			AddSelectedLine( size_t inLine )	{ mSelectedLines.insert(inLine); IncrementChangeCount(); };
	
	virtual bool			GetLockText()						{ return mLockText; };
	virtual void			SetLockText( bool inST )			{ mLockText = inST; };
	
	TFieldStyle				GetStyle()							{ return mFieldStyle; };
	virtual void			SetStyle( TFieldStyle s )			{ mFieldStyle = s; IncrementChangeCount(); };
	
	virtual bool			GetSharedText()					{ return mSharedText; };
	virtual void			SetSharedText( bool inST )		{ mSharedText = inST; IncrementChangeCount(); };
	
	virtual bool			GetAutoSelect()					{ return mAutoSelect; };
	virtual void			SetAutoSelect( bool inST )		{ mAutoSelect = inST; IncrementChangeCount(); };
	virtual bool			GetCanSelectMultipleLines()				{ return mMultipleLines; };
	virtual void			SetCanSelectMultipleLines( bool inST )	{ mMultipleLines = inST; IncrementChangeCount(); };
	
	virtual void			SetHasHorizontalScroller( bool inHS )	{ mHasHorizontalScroller = inHS; IncrementChangeCount(); };
	bool					GetHasHorizontalScroller()				{ return mHasHorizontalScroller; };
	virtual void			SetHasVerticalScroller( bool inHS )		{ mHasVerticalScroller = inHS; IncrementChangeCount(); };
	bool					GetHasVerticalScroller()				{ return mHasVerticalScroller; };
	virtual void			SetHasColumnHeaders( bool inHS )		{ mHasColumnHeaders = inHS; IncrementChangeCount(); };
	bool					GetHasColumnHeaders()					{ return mHasColumnHeaders; };

	virtual bool			GetDontWrap()					{ return mDontWrap; };
	virtual void			SetDontWrap( bool inST )		{ mDontWrap = inST; IncrementChangeCount(); };

	virtual bool			GetDontSearch()					{ return mDontSearch; };
	virtual void			SetDontSearch( bool inST )		{ mDontSearch = inST; IncrementChangeCount(); };
	virtual bool			GetAutoTab()					{ return mAutoTab; };
	virtual void			SetAutoTab( bool inST )			{ mAutoTab = inST; IncrementChangeCount(); };
	
	virtual void			SetCursorID( ObjectID inID )	{ mCursorID = inID; IncrementChangeCount(); };
	virtual ObjectID		GetCursorID()					{ return mCursorID; };

	virtual std::string		GetTextFont()					{ return mFont; };
	virtual int				GetTextSize()					{ return mTextSize; };
	virtual TPartTextStyle	GetTextStyle()					{ return mTextStyle; };
	virtual TPartTextAlign	GetTextAlign()					{ return mTextAlign; };
	virtual void			SetTextFont( std::string f )	{ mFont = f; };
	virtual void			SetTextSize( int s )			{ mTextSize = s; };
	virtual void			SetTextStyle( TPartTextStyle s ){ mTextStyle = s; };
	virtual void			SetTextAlign( TPartTextAlign a ){ mTextAlign = a; };
	
	virtual void			GetSelectedRange( LEOChunkType* outType, size_t* outStartOffs, size_t* outEndOffs ) = 0;
	virtual void			SetSelectedRange( LEOChunkType inType, size_t inStartOffs, size_t inEndOffs ) = 0;
	
	virtual void			GoToSleep()								{ if( mNeedsToImportTextFromView ) LoadChangedTextFromView(); };
	
	const CColumnInfo&		GetColumnInfo( size_t idx ) const		{ return mColumns[idx]; };
	
protected:
	~CFieldPart()	{};
	
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElement( tinyxml2::XMLElement * inElement );
	
	virtual void			LoadChangedTextStylesIntoView()			{ mNeedsToImportTextFromView = false; };
	virtual void			LoadChangedTextFromView()				{};
	virtual void			ApplyChangedSelectedLinesToView()		{};
	
	virtual const char*		GetIdentityForDump()	{ return "Field"; };
	virtual void			DumpProperties( size_t inIndent );

	bool					ParseRowColumnString( const char* inPropertyName, LEOInteger *outRow, LEOInteger *outColumn );

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
	int				mTextHeight;
	bool			mHasHorizontalScroller;
	bool			mHasVerticalScroller;
	bool			mHasColumnHeaders;
	bool			mNeedsToImportTextFromView;		// Did the text in the view change and we haven't updated the part contents yet?
	TFieldStyle		mFieldStyle;
	std::vector<CColumnInfo>	mColumns;
	std::set<size_t>			mSelectedLines;
	ObjectID		mCursorID;
};

}

#endif /* defined(__Stacksmith__CFieldPart__) */
