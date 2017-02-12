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

#if __OBJC__
@class NSImage;
typedef NSImage*		WILDNSImagePtr;
#else
#include <objc/objc.h>
typedef struct NSImage*	WILDNSImagePtr;
#endif

class CMacScriptableObjectBase
{
public:
	CMacScriptableObjectBase()			{};
	virtual ~CMacScriptableObjectBase()	{};
	
	virtual WILDNSImagePtr	GetDisplayIcon() = 0;
	virtual Class			GetPropertyEditorClass() = 0;
	virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) = 0;
	virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) = 0;
};

#endif /* defined(__Stacksmith__CMacScriptableObjectBase__) */
