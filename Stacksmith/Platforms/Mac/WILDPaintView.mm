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
#include "CPaintEngineRegularPolygonTool.h"
#include "CPaintEnginePolygonTool.h"


using namespace Carlson;


#define DEFAULT_TOOL		polygonTool


@interface WILDPaintView ()
{
	NSTrackingArea				*	mouseMoveTrackingArea;
	CChangeAreaTrackingImageCanvas	imgCanvas;			// Actual picture.
	CChangeAreaTrackingImageCanvas	temporaryCanvas;	// Used while tracking.
	CPaintEngine					paintEngine;
	CPaintEngineBrushTool			brushTool;
	CPaintEngineOvalTool			ovalTool;
	CPaintEnginePencilTool			pencilTool;
	CPaintEngineRegularPolygonTool	regPolygonTool;
	CPaintEnginePolygonTool			polygonTool;
}

@end


@implementation WILDPaintView

-(id)	initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if( self )
	{
		paintEngine.SetCurrentTool( &DEFAULT_TOOL );
	}
	return self;
}


-(id)	initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	if( self )
	{
		paintEngine.SetCurrentTool( &DEFAULT_TOOL );
	}
	return self;
}


-(void)	dealloc
{
	[mouseMoveTrackingArea release];
	mouseMoveTrackingArea = nil;
	
	[super dealloc];
}


-(void)	setFrame: (NSRect)inBox
{
	[super setFrame: inBox];
	
	self.bounds = (NSRect){ { 0, 0 }, { inBox.size.width / 8.0, inBox.size.height / 8.0 } };
}


-(void)	mouseEntered: (NSEvent *)event
{
	[[NSCursor crosshairCursor] push];
}


-(void)	mouseExited: (NSEvent *)event
{
	[[NSCursor crosshairCursor] pop];
}


-(void)	mouseMoved: (NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	pos.x = trunc(pos.x);
	pos.y = trunc(pos.y);

	imgCanvas.ClearDirtyRects();
	temporaryCanvas.ClearDirtyRects();
	
	paintEngine.MouseMovedToPoint( CPoint(pos) );
	
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
	for( CRect dirtyBox : temporaryCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
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
	pos.x = trunc(pos.x);
	pos.y = trunc(pos.y);
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
	pos.x = trunc(pos.x);
	pos.y = trunc(pos.y);

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
	pos.x = trunc(pos.x);
	pos.y = trunc(pos.y);

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


-(void) updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if( mouseMoveTrackingArea )
	{
		[mouseMoveTrackingArea release];
		mouseMoveTrackingArea = nil;
	}
	
	NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);

	mouseMoveTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                    options:options
                                                      owner:self
                                                   userInfo:nil];
	[self addTrackingArea: mouseMoveTrackingArea];
}

@end
