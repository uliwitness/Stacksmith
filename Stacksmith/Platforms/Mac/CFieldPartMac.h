//
//  CFieldPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CFieldPartMac__
#define __Stacksmith__CFieldPartMac__


#include "CFieldPart.h"
#include "CMacPartBase.h"
#include <climits>
#import "WILDFieldInfoViewController.h"
#import "WILDScrollView.h"


@class WILDFieldDelegate;
@class WILDTextView;
@class WILDTableView;
@class WILDSearchField;


namespace Carlson {

class CAttributedString;


class CFieldPartMac : public CFieldPart, public CMacPartBase
{
public:
	CFieldPartMac( CLayer *inOwner );

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	SetPeeking( bool inState )			{ ApplyPeekingStateToView(inState, mView); };
	virtual void	LoadChangedTextStylesIntoView();
	virtual void	LoadChangedTextFromView();
	virtual void	SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual void	SetHasHorizontalScroller( bool inHS );
	virtual void	SetHasVerticalScroller( bool inHS );
	virtual void	SetHasColumnHeaders( bool inCH );
	virtual NSFont*	GetMacFont();
	
	virtual void	SetVisible( bool visible );
	virtual void	SetEnabled( bool n );
	virtual void	SetLockText( bool n );
	virtual void	SetAutoSelect( bool n );
	virtual void	SetFillColor( int r, int g, int b, int a );
	virtual void	SetLineColor( int r, int g, int b, int a );
	virtual void	SetShadowColor( int r, int g, int b, int a );
	virtual void	SetShadowOffset( double w, double h );
	virtual void	SetShadowBlurRadius( double r );
	virtual void	SetLineWidth( int w );
	virtual void	SetBevelWidth( int bevel );
	virtual void	SetBevelAngle( int a );
	virtual void	SetCursorID( ObjectID inID );
	virtual void	GetSelectedRange( LEOChunkType* outType, size_t* outStartOffs, size_t* outEndOffs );
	virtual void	SetSelectedRange( LEOChunkType inType, size_t inStartOffs, size_t inEndOffs );
	virtual void	SetToolTip( const std::string& inToolTip )	{ CFieldPart::SetToolTip(inToolTip); [mView setToolTip: [NSString stringWithUTF8String: inToolTip.c_str()]]; };
	virtual void	SetPartLayoutFlags( TPartLayoutFlags inFlags );
	virtual void	SetScript( std::string inScript );
	
	virtual NSView*	GetView();
	virtual NSDictionary*			GetCocoaAttributesForPart();
	
	virtual Class	GetPropertyEditorClass()	{ return [WILDFieldInfoViewController class]; };

	static NSAttributedString	*	GetCocoaAttributedString( const CAttributedString& attrStr, NSDictionary * defaultAttrs, size_t startOffs = 0, size_t endOffs = SIZE_T_MAX );
	static void						SetAttributedStringWithCocoa( CAttributedString& stringToSet, NSAttributedString* cocoaAttrStr );
	static size_t					UTF8OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr );
	static size_t					UTF32OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr );
	static NSInteger				UTF16OffsetFromUTF32OffsetInCocoaString( size_t inUTF32Offs, NSString* cocoaStr );
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };
	
protected:
	~CFieldPartMac()	{ DestroyView(); };

	virtual void		SetStyle( TFieldStyle inFieldStyle );

	WILDScrollView*		mView;
	WILDFieldDelegate*	mMacDelegate;
	WILDTableView *		mTableView;
	WILDTextView	*	mTextView;
	WILDSearchField*	mSearchField;
};


}

#endif /* defined(__Stacksmith__CFieldPartMac__) */
