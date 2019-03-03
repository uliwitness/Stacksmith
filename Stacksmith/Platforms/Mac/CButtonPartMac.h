//
//  CButtonPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CButtonPartMac__
#define __Stacksmith__CButtonPartMac__

#include "CButtonPart.h"
#include "CMacPartBase.h"
#import "WILDButtonInfoViewController.h"


@class WILDButtonView;


namespace Carlson {


class CButtonPartMac : public CButtonPart, public CMacPartBase
{
public:
	CButtonPartMac( CLayer *inOwner ) : CButtonPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	SetName( const std::string& inStr );
	virtual void	SetPeeking( bool inState );
	virtual void	SetHighlight( bool inHighlight );
	virtual void	SetHighlightForTracking( bool inHighlight );
	virtual void	SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual bool	SetTextContents( const std::string &inString );
	virtual void	SetShowName( bool inShowName );
	virtual void	SetVisible( bool visible )		{ CButtonPart::SetVisible(visible); [mView setHidden: !visible]; };
	
	virtual void	SetFillColor( int r, int g, int b, int a );
	virtual void	SetLineColor( int r, int g, int b, int a );
	virtual void	SetShadowColor( int r, int g, int b, int a );
	virtual void	SetShadowOffset( double w, double h );
	virtual void	SetShadowBlurRadius( double r );
	virtual void	SetLineWidth( int w );
	virtual void	SetBevelWidth( int bevel );
	virtual void	SetBevelAngle( int a );
	
	virtual NSView*	GetView();
	virtual void	SetToolTip( const std::string& inToolTip );
	
	virtual void	SetIconID( ObjectID inID );
	virtual void	SetCursorID( ObjectID inID );
	
	virtual void	SetPartLayoutFlags( TPartLayoutFlags inFlags );

	virtual void	SetScript( std::string inScript );
	
	virtual void	PrepareMouseUp();
	virtual void	SetStyle( TButtonStyle inButtonStyle );
	virtual void	ToolChangedFrom( TTool inOldTool );
	virtual void	WillBeDeleted()					{ CMacPartBase::WillBeDeleted(); };
	
	virtual NSImage*	GetDisplayIcon()			{ return [NSImage imageNamed: @"ButtonIconSmall"]; };
	virtual Class		GetPropertyEditorClass()	{ return [WILDButtonInfoViewController class]; };
	
	virtual void		OpenScriptEditorAndShowOffset( size_t byteOffset )	{ CMacPartBase::OpenScriptEditorAndShowOffset(byteOffset); };
	virtual void		OpenScriptEditorAndShowLine( size_t lineIndex )	{ CMacPartBase::OpenScriptEditorAndShowLine(lineIndex); };
	virtual void		OpenContentsEditor()		{ CMacPartBase::OpenContentsEditor(); };

	virtual void		Trigger();
	
	virtual void		SetTextFont( std::string inName )
	{
		CButtonPart::SetTextFont( inName );
		
		NSFont*	theFont = [GetCocoaAttributesForPart() objectForKey: NSFontAttributeName];
		[mView setFont: theFont];
	}

	virtual void		SetTextSize( int s )
	{
		CButtonPart::SetTextSize( s );
		
		NSFont*	theFont = [GetCocoaAttributesForPart() objectForKey: NSFontAttributeName];
		[mView setFont: theFont];
	}
	
	virtual void		SetTextStyle( TPartTextStyle s )
	{
		CButtonPart::SetTextStyle( s );
		
		NSFont*	theFont = [GetCocoaAttributesForPart() objectForKey: NSFontAttributeName];
		[mView setFont: theFont];
	}

protected:
	~CButtonPartMac()	{ DestroyView(); };
	
	virtual void	ApplyChangedSelectedLinesToView();
	
	WILDButtonView	*	mView;
};


}

#endif /* defined(__Stacksmith__CButtonPartMac__) */
