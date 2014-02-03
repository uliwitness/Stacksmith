//
//  WILDStackWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__WILDStackWindowController__
#define __Stacksmith__WILDStackWindowController__

#import <Cocoa/Cocoa.h>


namespace Carlson {

class CStackMac;
class CPart;

}


@class WILDFlippedContentView;


@interface WILDStackWindowController : NSWindowController <NSWindowDelegate>
{
	Carlson::CStackMac	*	mStack;
	CALayer				*	mSelectionOverlay;	// Draw "peek" outline and selection rectangles in this layer.
	NSImageView			*	mBackgroundImageView;
	NSImageView			*	mCardImageView;
	BOOL					mWasVisible;
	NSPopover			*	mPopover;
	WILDFlippedContentView*	mContentView;
}

-(id)	initWithCppStack: (Carlson::CStackMac*)inStack;

-(void)	removeAllViews;
-(void)	createAllViews;

-(void)	drawBoundingBoxes;
-(void)	updateStyle;

-(Carlson::CStackMac*)	cppStack;

-(void)	showWindowOverPart: (Carlson::CPart*)overPart;

@end


@interface WILDFlippedContentView : NSView
{
	NSView				*		lastHitView;
	Carlson::CStackMac	*		mStack;
	WILDStackWindowController*	mOwningStackWindowController;
}

@property (assign,nonatomic) Carlson::CStackMac*		stack;
@property (assign,nonatomic) WILDStackWindowController*	owningStackWindowController;

@end


#endif /* defined(__Stacksmith__WILDStackWindowController__) */
