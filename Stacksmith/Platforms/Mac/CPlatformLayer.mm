//
//  CPlatformLayer.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CPlatformLayer.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardInfoViewController.h"
#import "WILDBackgroundInfoViewController.h"
#include "CCard.h"


using namespace Carlson;


CPlatformLayer::~CPlatformLayer()
{
	[mScriptEditor close];
	[mScriptEditor release];
}


void	CPlatformLayer::OpenScriptEditorAndShowOffset( size_t byteOffset )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: this];
	
	[mScriptEditor showWindow: nil];
	if( byteOffset != SIZE_T_MAX )
		[mScriptEditor goToCharacter: byteOffset];
}


void	CPlatformLayer::OpenScriptEditorAndShowLine( size_t lineIndex )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: this];
	
	[mScriptEditor showWindow: nil];
	if( lineIndex != SIZE_T_MAX )
		[mScriptEditor goToLine: lineIndex];
}


Class	CPlatformLayer::GetPropertyEditorClass()
{
	if( dynamic_cast<CCard*>(this) )
	{
		return [WILDCardInfoViewController class];
	}
	else
	{
		return [WILDBackgroundInfoViewController class];
	}
}


NSImage*	CPlatformLayer::GetDisplayIcon()
{
	static NSImage*	sLayerIcon = nil;
	if( !sLayerIcon )
		sLayerIcon = [[NSImage imageNamed: @"CardIconSmall"] retain];
	return sLayerIcon;
}

