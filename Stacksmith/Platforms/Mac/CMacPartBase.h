//
//  CMacPartBase.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	Mac-specific mix-in class for all our CParts. CStackMac creates
	subclasses of each part type mixed in with this class, which it
	then asks to create/destroy the Mac-specific UI.
*/

#ifndef __Stacksmith__CMacPartBase__
#define __Stacksmith__CMacPartBase__

#import "WILDPartInfoViewController.h"
#import <Cocoa/Cocoa.h>
#include "CMacScriptableObjectBase.h"
#include "CVisiblePart.h"


@class WILDScriptEditorWindowController;
@class WILDContentsEditorWindowController;


#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_9
typedef NSUInteger NSAutoresizingMaskOptions;
#endif

namespace Carlson {


class CMacPartBase : public CMacScriptableObjectBase
{
public:
	CMacPartBase() {};
	
	virtual void	CreateViewIn( NSView* inSuperView ) = 0;
	virtual void	DestroyView() = 0;
	virtual void	ApplyPeekingStateToView( bool inState, NSView* inView )
	{
		//inView.layer.borderWidth = inState? 1 : 0;
		//inView.layer.borderColor = inState? [NSColor grayColor].CGColor : NULL;
	}
	virtual NSView*			GetView()					{ return NULL; };
	virtual NSImage*		GetDisplayIcon()			{ return [NSImage imageNamed: @"FieldIconSmall"]; };
	virtual void			SetCocoaAttributesForPart( NSDictionary* inAttrs );
	virtual NSDictionary*	GetCocoaAttributesForPart();
	virtual Class			GetPropertyEditorClass()	{ return [WILDPartInfoViewController class]; };
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset );
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex );
	virtual void		OpenContentsEditor();
	
protected:
	virtual ~CMacPartBase() { [mScriptEditor release]; mScriptEditor = nil; [mContentsEditor release]; mContentsEditor = nil; };
	NSAutoresizingMaskOptions	GetCocoaResizeFlags( TPartLayoutFlags inFlags );
	
	WILDScriptEditorWindowController*	mScriptEditor;
	WILDContentsEditorWindowController*	mContentsEditor;
};


}

#endif /* defined(__Stacksmith__CMacPartBase__) */
