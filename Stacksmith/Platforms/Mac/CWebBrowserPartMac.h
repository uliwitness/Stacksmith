//
//  CWebBrowserPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CWebBrowserPartMac__
#define __Stacksmith__CWebBrowserPartMac__


#include "CWebBrowserPart.h"
#include "CMacPartBase.h"
#import "WILDWebBrowserInfoViewController.h"


@class WKWebView;
@class WILDWebBrowserDelegate;


namespace Carlson {


class CWebBrowserPartMac : public CWebBrowserPart, public CMacPartBase
{
public:
	CWebBrowserPartMac( CLayer *inOwner ) : CWebBrowserPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	WillBeDeleted()					{ CMacPartBase::WillBeDeleted(); };
	virtual void	SetPeeking( bool inState );
	virtual void	SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual void	SetVisible( bool visible )		{ CWebBrowserPart::SetVisible(visible); [mView setHidden: !visible]; };
	virtual void	LoadCurrentURL( const std::string& inURL );	// Triggers view update.
	virtual void	SetToolTip( const std::string& inToolTip );
	virtual NSView*	GetView();
	virtual Class	GetPropertyEditorClass()	{ return [WILDWebBrowserInfoViewController class]; };
	
	virtual void	SetPartLayoutFlags( TPartLayoutFlags inFlags );
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };
	
protected:
	~CWebBrowserPartMac()	{ DestroyView(); };
	
	WKWebView				*mView;
	WILDWebBrowserDelegate	*mMacDelegate;
};


}

#endif /* defined(__Stacksmith__CWebBrowserPartMac__) */
