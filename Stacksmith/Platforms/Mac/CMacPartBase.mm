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
