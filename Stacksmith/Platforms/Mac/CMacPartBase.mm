//
//  CMacPartBase.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMacPartBase.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDContentsEditorWindowController.h"
#include "CPart.h"


using namespace Carlson;


void	CMacPartBase::OpenScriptEditorAndShowOffset( size_t byteOffset )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	
	[mScriptEditor showWindow: nil];
	if( byteOffset != SIZE_T_MAX )
		[mScriptEditor goToCharacter: byteOffset];
}


void	CMacPartBase::OpenScriptEditorAndShowLine( size_t lineIndex )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	
	[mScriptEditor showWindow: nil];
	if( lineIndex != SIZE_T_MAX )
		[mScriptEditor goToLine: lineIndex];
}


void	CMacPartBase::OpenContentsEditor()
{
	if( !mContentsEditor )
		mContentsEditor = [[WILDContentsEditorWindowController alloc] initWithPart: dynamic_cast<CPart*>(this)];
	[mContentsEditor showWindow: nil];
}


NSAutoresizingMaskOptions	CMacPartBase::GetCocoaResizeFlags( TPartLayoutFlags inFlags )
{
	// NB: HyperCard starts coordinates at top left, Cocoa generally starts them
	//	at the lower left, so the top is actually the highest Y coordinate for Cocoa.
	
	NSAutoresizingMaskOptions	cocoaFlags = 0;
	switch( PART_H_LAYOUT_MODE(inFlags) )
	{
		case EPartLayoutAlignLeft:
			cocoaFlags |= NSViewMaxXMargin;
			break;
		case EPartLayoutAlignHBoth:
			cocoaFlags |= NSViewWidthSizable;
			break;
		case EPartLayoutAlignRight:
			cocoaFlags |= NSViewMinXMargin;
			break;
	}
	switch( PART_V_LAYOUT_MODE(inFlags) )
	{
		case EPartLayoutAlignTop:
			cocoaFlags |= NSViewMaxYMargin;	// Cocoa coords start in lower left.
			break;
		case EPartLayoutAlignVBoth:
			cocoaFlags |= NSViewHeightSizable;
			break;
		case EPartLayoutAlignBottom:
			cocoaFlags |= NSViewMinYMargin;	// Cocoa coords start in lower left.
			break;
	}
	return cocoaFlags;
}

