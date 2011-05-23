//
//  WILDGuidelineView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 23.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDGuidelineView : NSView
{
	NSMutableArray			*mGuidelines;
}

-(void)	addGuidelineAt: (CGFloat)pos horizontal: (BOOL)inIsHorizontal color: (NSColor*)inColor;
-(void)	removeAllGuidelines;

@end
