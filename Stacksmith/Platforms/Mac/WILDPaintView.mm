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
#include "CPaintEngineOvalTool.h"
#include "CPaintEnginePencilTool.h"


using namespace Carlson;


@interface WILDPaintView ()
{
	CChangeAreaTrackingImageCanvas	imgCanvas;			// Actual picture.
	CChangeAreaTrackingImageCanvas	temporaryCanvas;	// Used while tracking.
	CPaintEngine					paintEngine;
	CPaintEngineBrushTool			brushTool;
	CPaintEngineOvalTool			ovalTool;
	CPaintEnginePencilTool			pencilTool;
}

@end


@implementation WILDPaintView

-(id)	initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if( self )
	{
		paintEngine.SetCurrentTool( &pencilTool );
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	if( self )
	{
		paintEngine.SetCurrentTool( &pencilTool );
	}
	return self;
}


-(void)	setFrame: (NSRect)inBox
{
	[super setFrame: inBox];
	
	self.bounds = (NSRect){ { 0, 0 }, { inBox.size.width / 8.0, inBox.size.height / 8.0 } };
}


-(void)	drawRect: (NSRect)dirtyRect
{
	if( !imgCanvas.IsValid() )
		imgCanvas.InitWithSize( CSize(self.bounds.size) );
	if( !temporaryCanvas.IsValid() )
		temporaryCanvas.InitWithSize( CSize(self.bounds.size) );
	
	NSImageInterpolation oldInterpolation = [NSGraphicsContext currentContext].imageInterpolation;
	[NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationNone;
	
	[imgCanvas.GetMacImage() drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
    [temporaryCanvas.GetMacImage() drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
	
	[NSGraphicsContext currentContext].imageInterpolation = oldInterpolation;
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
	paintEngine.SetLineThickness( 2 );
	paintEngine.SetLineColor( CColor( 0.0, 0.0, 65535.0, 65535.0 ) );
	
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	pos.x = trunc(pos.x) +0.5;
	pos.y = trunc(pos.y) +0.5;
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
	pos.x = trunc(pos.x) +0.5;
	pos.y = trunc(pos.y) +0.5;

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
	pos.x = trunc(pos.x) +0.5;
	pos.y = trunc(pos.y) +0.5;

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
