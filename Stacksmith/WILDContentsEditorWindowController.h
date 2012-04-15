//
//  WILDContentsEditorWindowController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDPart;
@class WILDCardView;


@interface WILDContentsEditorWindowController : NSWindowController
{
	WILDPart*						mContainer;			// Not retained, this is our owner!
	IBOutlet NSTextView*			mTextView;			// Part text.
	NSRect							mGlobalStartRect;	// For opening animation.
	WILDCardView*					mCardView;
}

-(id)		initWithPart: (WILDPart*)inContainer;

-(void)		setGlobalStartRect: (NSRect)theBox;

-(void)		setCardView: (WILDCardView*)inView;

@end
