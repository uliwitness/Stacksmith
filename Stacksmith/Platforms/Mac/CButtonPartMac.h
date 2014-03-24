//
//  CButtonPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CButtonPartMac__
#define __Stacksmith__CButtonPartMac__

#include "CButtonPart.h"
#include "CMacPartBase.h"
#import "WILDButtonInfoViewController.h"


@class WILDButtonView;


namespace Carlson {


class CButtonPartMac : public CButtonPart, public CMacPartBase
{
public:
	CButtonPartMac( CLayer *inOwner ) : CButtonPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	SetName( const std::string& inStr );
	virtual void	SetPeeking( bool inState );
	virtual void	SetHighlight( bool inHighlight );
	virtual void	SetHighlightForTracking( bool inHighlight );
	virtual void	SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual bool	SetTextContents( const std::string &inString );
	virtual void	SetShowName( bool inShowName );
	virtual void	SetVisible( bool visible )		{ CButtonPart::SetVisible(visible); [mView setHidden: !visible]; };
	virtual NSView*	GetView();
	
	virtual void	SetIconID( ObjectID inID );
	
	virtual void	PrepareMouseUp();
	virtual void	SetStyle( TButtonStyle inButtonStyle );
	
	virtual NSImage*	GetDisplayIcon()			{ return [NSImage imageNamed: @"ButtonIconSmall"]; };
	virtual Class		GetPropertyEditorClass()	{ return [WILDButtonInfoViewController class]; };
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };
	
protected:
	~CButtonPartMac()	{ DestroyView(); };
	
	virtual void	ApplyChangedSelectedLinesToView();
	
	WILDButtonView	*	mView;
};


}

#endif /* defined(__Stacksmith__CButtonPartMac__) */
