//
//  CMacScriptableObjectBase.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMacScriptableObjectBase__
#define __Stacksmith__CMacScriptableObjectBase__

#include <cstddef>
#include <objc/objc.h>

#if __OBJC__
@class NSImage;
typedef NSImage*		WILDNSImagePtr;
@class WILDScriptEditorWindowController;
typedef WILDScriptEditorWindowController *WILDScriptEditorWindowControllerPtr;
#else
typedef struct NSImage*	WILDNSImagePtr;
typedef struct WILDScriptEditorWindowController *WILDScriptEditorWindowControllerPtr;
#endif

class CMacScriptableObjectBase
{
public:
	CMacScriptableObjectBase()			{}
	virtual ~CMacScriptableObjectBase();
	
	virtual WILDNSImagePtr	GetDisplayIcon() = 0;
	virtual Class			GetPropertyEditorClass() = 0;
	virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset );
	virtual void			OpenScriptEditorAndShowLine( size_t lineIndex );
	
	void					SetMacScriptEditor( WILDScriptEditorWindowControllerPtr inController );

protected:
	WILDScriptEditorWindowControllerPtr	mScriptEditor = nil;
};

#endif /* defined(__Stacksmith__CMacScriptableObjectBase__) */
