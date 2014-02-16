//
//  CMacScriptableObjectBase.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMacScriptableObjectBase__
#define __Stacksmith__CMacScriptableObjectBase__

#if __OBJC__
@class NSImage;
typedef NSImage*		WILDNSImagePtr;
#else
typedef struct NSImage*	WILDNSImagePtr;
#endif

class CMacScriptableObjectBase
{
public:
	CMacScriptableObjectBase()			{};
	virtual ~CMacScriptableObjectBase()	{};
	
	virtual WILDNSImagePtr	GetDisplayIcon() = 0;
};

#endif /* defined(__Stacksmith__CMacScriptableObjectBase__) */
