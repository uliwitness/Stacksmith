//
//  CTimerPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CTimerPartMac__
#define __Stacksmith__CTimerPartMac__

#include "CTimerPart.h"
#include "CMacPartBase.h"
#import "WILDTimerInfoViewController.h"


namespace Carlson
{

class CTimerPartMac : public CTimerPart, public CMacPartBase
{
public:
	explicit CTimerPartMac( CLayer *inOwner ) : CTimerPart( inOwner ), mView(NULL) {};
	
	virtual Class		GetPropertyEditorClass()	{ return [WILDTimerInfoViewController class]; };
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()	{ CMacPartBase::OpenContentsEditor(); };
	
	virtual void		CreateViewIn( NSView* inSuperView );
	virtual void		DestroyView();
	virtual NSView*		GetView()					{ return mView; };
	virtual void		WillBeDeleted()				{ CMacPartBase::WillBeDeleted(); };
	virtual NSImage*	GetDisplayIcon();
	
	virtual void		SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b );


protected:
	NSImageView*	mView;	// Only created & shown while editing.
};

}

#endif /* defined(__Stacksmith__CTimerPartMac__) */
