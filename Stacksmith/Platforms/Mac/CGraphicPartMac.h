//
//  CGraphicPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CGraphicPartMac__
#define __Stacksmith__CGraphicPartMac__

#include "CGraphicPart.h"
#include "CMacPartBase.h"
//#import "WILDGraphicInfoViewController.h"


namespace Carlson
{

class CGraphicPartMac : public CGraphicPart, public CMacPartBase
{
public:
	explicit CGraphicPartMac( CLayer *inOwner ) : CGraphicPart( inOwner ), mView(NULL) {};
	
//	virtual Class		GetPropertyEditorClass()	{ return [WILDGraphicInfoViewController class]; };
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };
	
	virtual void		CreateViewIn( NSView* inSuperView );
	virtual void		DestroyView();
	virtual NSView*		GetView()					{ return mView; };
	virtual NSImage*	GetDisplayIcon();
	
	virtual void		SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b );
	virtual void		SetPartLayoutFlags( TPartLayoutFlags inFlags );
	virtual void		SetFillColor( int r, int g, int b, int a );
	virtual void		SetLineColor( int r, int g, int b, int a );
	virtual void		SetShadowColor( int r, int g, int b, int a );
	virtual void		SetShadowOffset( double w, double h );
	virtual void		SetShadowBlurRadius( double r );
	virtual void		SetLineWidth( int w );

	virtual void		AddPoint( LEONumber x, LEONumber y, LEONumber lineWidth );
	virtual void		UpdateLastPoint( LEONumber x, LEONumber y, LEONumber lineWidth );

protected:
	void				RebuildViewLayerPath();
	
	NSView*			mView;
};

}

#endif /* defined(__Stacksmith__CGraphicPartMac__) */
