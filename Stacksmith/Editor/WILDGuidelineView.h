//
//  WILDGuidelineView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 23.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDPartView;


@interface WILDGuidelineView : NSView
{
	NSMutableArray			*mGuidelines;
	NSMutableArray			*mPartViews;
	NSMutableArray			*mSelectedPartViews;
}

-(void)	addGuidelineAt: (CGFloat)pos horizontal: (BOOL)inIsHorizontal color: (NSColor*)inColor;
-(void)	removeAllGuidelines;

-(void)	addSelectedPartView: (WILDPartView*)inPartView;
-(void)	removeSelectedPartView: (WILDPartView*)inPartView;
-(void)	removeAllSelectedPartViews;

-(void)	addPartView: (WILDPartView*)inPartView;
-(void)	removePartView: (WILDPartView*)inPartView;
-(void)	removeAllPartViews;

@end
