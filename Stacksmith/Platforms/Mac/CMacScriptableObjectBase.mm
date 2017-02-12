//
//  CMacScriptableObjectBase.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMacScriptableObjectBase.h"
#import "WILDScriptEditorWindowController.h"
#import "UKHelperMacros.h"


using namespace Carlson;


CMacScriptableObjectBase::~CMacScriptableObjectBase()
{
	[mScriptEditor close];
	DESTROY_DEALLOC(mScriptEditor);
}


void	CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( size_t byteOffset )
{
	if( !mScriptEditor )
	{
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	}
	
	[mScriptEditor showWindow: nil];
	if( byteOffset != SIZE_T_MAX )
		[mScriptEditor goToCharacter: byteOffset];
}


void	CMacScriptableObjectBase::OpenScriptEditorAndShowLine( size_t lineIndex )
{
	if( !mScriptEditor )
	{
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: dynamic_cast<CConcreteObject*>(this)];
	}
	
	[mScriptEditor showWindow: nil];
	if( lineIndex != SIZE_T_MAX )
		[mScriptEditor goToLine: lineIndex];
}


void	CMacScriptableObjectBase::SetMacScriptEditor( WILDScriptEditorWindowControllerPtr inController )
{
	ASSIGN(mScriptEditor, inController);
}
