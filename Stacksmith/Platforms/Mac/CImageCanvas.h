//
//  CImageCanvas.h
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#ifndef CImageCanvas_h
#define CImageCanvas_h

#include "CCanvas.h"
#include <string>


#if __OBJC__
@class NSImage;
typedef NSImage*		WILDNSImagePtr;
#else
typedef struct NSImage*	WILDNSImagePtr;
#endif

namespace Carlson {


class CImageCanvas : public CCanvas
{
public:
	CImageCanvas() : mImage(NULL) {}
	CImageCanvas( const CSize& inSize );
	CImageCanvas( const std::string& inImageURL );
	CImageCanvas( CImageCanvas&& inOriginal );
	explicit CImageCanvas(WILDNSImagePtr inImage);
	~CImageCanvas();
	
	virtual bool	IsValid()	{ return mImage != NULL; }
	
	virtual CRect	GetRect();
	
	virtual void	BeginDrawing();
	virtual void	EndDrawing();
	
	CImageCanvas	Copy();
	
	WILDNSImagePtr	GetMacImage()	{ return mImage; }	// Only for use by platform-specific code to e.g. hand icons to OS controls.
	
	virtual CImageCanvas& operator =( const CImageCanvas& inOriginal );
	
protected:
	WILDNSImagePtr	mImage;

friend class CCanvas;
};


} /* namespace Carlson */

#endif /* CImageCanvas_h */
