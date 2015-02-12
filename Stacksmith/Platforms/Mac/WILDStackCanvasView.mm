//
//  WILDStackCanvasView.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-11.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDStackCanvasView.h"
#include "CDocument.h"
#include "CStack.h"
#import "NSImage+NiceScaling.h"


using namespace Carlson;


@implementation WILDStackCanvasView

-(void)	drawRect: (NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedHue:0.646 saturation:0.369 brightness:0.332 alpha:1.000] set];
	NSRectFillUsingOperation( self.bounds, NSCompositeCopy );
	NSImage*	stackImage = [NSImage imageNamed: @"Stack"];
	NSRect		box = { { 64, 0 }, { 128, 128 } };
	
	box.origin.y += self.bounds.size.height -128 -36;
	
	NSRect		textBox = box;
	textBox.size.height = 24;
	textBox.origin.y = box.origin.y -textBox.size.height;
	
	size_t	numStacks = self.owningDocument->GetNumStacks();
	for( size_t x = 0; x < numStacks; x++ )
	{
		CStack* 		currStack = self.owningDocument->GetStack( x );
		NSImage*		img = stackImage;
		NSString*		nameStr = [NSString stringWithUTF8String: currStack->GetName().c_str()];
		std::string		thumbName = currStack->GetThumbnailName();
		
		if( thumbName.length() > 0 )
		{
			NSURL	*	thumbURL = [NSURL URLWithString: [NSString stringWithUTF8String: currStack->GetURL().c_str()]];
			thumbURL = [thumbURL.URLByDeletingLastPathComponent URLByAppendingPathComponent: [NSString stringWithUTF8String: thumbName.c_str()]];
			img = [[[NSImage alloc] initWithContentsOfURL: thumbURL] autorelease];
		}
		
		NSDictionary*	attrs = @{ NSFontAttributeName: [NSFont systemFontOfSize: [NSFont systemFontSize]], NSForegroundColorAttributeName: NSColor.darkGrayColor };
		NSSize			attrSize = [nameStr sizeWithAttributes: attrs];
		textBox.origin.x = NSMidX(box) -truncf(attrSize.width / 2);
		textBox.size.width = attrSize.width;
		textBox.size.height = attrSize.height;
		
		NSRect		imgBox = box;
		imgBox.size = [img scaledSizeToFitSize: box.size];
		[img drawInRect: imgBox];
		NSRect			textCartoucheBox = NSInsetRect(textBox,-10,-2);
		NSBezierPath* bp = [NSBezierPath bezierPathWithRoundedRect: textCartoucheBox xRadius: textCartoucheBox.size.height / 2 yRadius: textCartoucheBox.size.height / 2];
		[NSColor.whiteColor set];
		[bp fill];
		[nameStr drawAtPoint: textBox.origin withAttributes: attrs];
		
		box.origin.x += 128 + 64;
	}
}


-(BOOL)	isOpaque
{
	return NO;
}

@end
