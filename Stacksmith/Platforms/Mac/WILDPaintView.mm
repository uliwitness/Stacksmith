//
//  WILDPaintView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "WILDPaintView.h"
#include "CChangeAreaTrackingImageCanvas.h"
#include "CPaintEngine.h"
#include "CPaintEngineBrushTool.h"


using namespace Carlson;


@interface WILDPaintView ()
{
	CChangeAreaTrackingImageCanvas	imgCanvas;			// Actual picture.
	CChangeAreaTrackingImageCanvas	temporaryCanvas;	// Used while tracking.
	CPaintEngine					paintEngine;
	CPaintEngineBrushTool			brushTool;
}

@end


@implementation WILDPaintView

-(id)	initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if( self )
	{
		paintEngine.SetCurrentTool( &brushTool );
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	if( self )
	{
		paintEngine.SetCurrentTool( &brushTool );
	}
	return self;
}


-(void)	drawRect: (NSRect)dirtyRect
{
	if( !imgCanvas.IsValid() )
		imgCanvas.InitWithSize( CSize(self.bounds.size) );
	if( !temporaryCanvas.IsValid() )
		temporaryCanvas.InitWithSize( CSize(self.bounds.size) );
	
	[imgCanvas.GetMacImage() drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
    [temporaryCanvas.GetMacImage() drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
}


-(void) mouseDown: (NSEvent *)event
{
	if( !imgCanvas.IsValid() )
		imgCanvas.InitWithSize( CSize(self.bounds.size) );
	if( !temporaryCanvas.IsValid() )
		temporaryCanvas.InitWithSize( CSize(self.bounds.size) );

	paintEngine.SetCanvas( &imgCanvas );
	paintEngine.SetTemporaryCanvas( &temporaryCanvas );
	paintEngine.SetFillColor( CColor( 65535.0, 0.0, 0.0, 65535.0 ) );
	
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	temporaryCanvas.ClearDirtyRects();
	
	paintEngine.MouseDownAtPoint( CPoint(pos) );
		
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
	for( CRect dirtyBox : temporaryCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}


-(void) mouseDragged: (NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	temporaryCanvas.ClearDirtyRects();
	
	paintEngine.MouseDraggedToPoint( CPoint(pos) );
	
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
	for( CRect dirtyBox : temporaryCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}


-(void) mouseUp: (NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	temporaryCanvas.ClearDirtyRects();
	
	paintEngine.MouseReleasedAtPoint( CPoint(pos) );
	
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
	for( CRect dirtyBox : temporaryCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}

@end
