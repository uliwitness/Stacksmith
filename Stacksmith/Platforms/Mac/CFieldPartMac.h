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

@class WILDFieldDelegate;

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
	virtual void	SetVisible( bool visible )		{ CFieldPart::SetVisible(visible); [mView setHidden: !visible]; };
	virtual void	SetHasHorizontalScroller( bool inHS );
	virtual void	SetHasVerticalScroller( bool inHS );
	virtual NSView*	GetView();
	virtual NSDictionary*			GetCocoaAttributesForPart();

	static NSAttributedString	*	GetCocoaAttributedString( const CAttributedString& attrStr, NSDictionary * defaultAttrs, size_t startOffs = 0, size_t endOffs = SIZE_T_MAX );
	static void						SetAttributedStringWithCocoa( CAttributedString& stringToSet, NSAttributedString* cocoaAttrStr );
	
protected:
	~CFieldPartMac()	{ DestroyView(); };

	virtual void		SetFieldStyle( TFieldStyle inFieldStyle );

	NSScrollView*		mView;
	WILDFieldDelegate*	mMacDelegate;
	NSTableView *		mTableView;
	NSTextView	*		mTextView;
};


}

#endif /* defined(__Stacksmith__CFieldPartMac__) */
