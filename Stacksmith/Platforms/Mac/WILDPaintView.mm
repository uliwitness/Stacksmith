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


using namespace Carlson;


@interface WILDPaintView ()
{
	CChangeAreaTrackingImageCanvas	imgCanvas;
	CPaintEngine					paintEngine;
}

@end


@implementation WILDPaintView

-(void)	drawRect: (NSRect)dirtyRect
{
	if( !imgCanvas.IsValid() )
		imgCanvas.InitWithSize( CSize(self.bounds.size) );
    [imgCanvas.GetMacImage() drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
}


-(void) mouseDown: (NSEvent *)event
{
	if( !imgCanvas.IsValid() )
		imgCanvas.InitWithSize( CSize(self.bounds.size) );

	paintEngine.SetCanvas( &imgCanvas );
	paintEngine.SetFillColor( CColor( 65535.0, 0.0, 0.0, 65535.0 ) );
	
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	
	paintEngine.MouseDownAtPoint( CPoint(pos) );
		
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}


-(void) mouseDragged: (NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	
	paintEngine.MouseDraggedToPoint( CPoint(pos) );
	
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}


-(void) mouseUp: (NSEvent *)event
{
	NSPoint pos = [self convertPoint: event.locationInWindow fromView: nil];
	imgCanvas.ClearDirtyRects();
	
	paintEngine.MouseReleasedAtPoint( CPoint(pos) );
	
	for( CRect dirtyBox : imgCanvas.GetDirtyRects() )
	{
		[self setNeedsDisplayInRect: dirtyBox.GetMacRect()];
	}
}

@end
