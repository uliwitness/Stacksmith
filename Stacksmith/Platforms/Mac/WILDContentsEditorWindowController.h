//
//  WILDContentsEditorWindowController.h
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CPart;
}

@interface WILDContentsEditorWindowController : NSWindowController
{
	Carlson::CPart*					mContainer;			// Not retained, this is our owner!
	IBOutlet NSTextView*			mTextView;			// Part text.
	NSRect							mGlobalStartRect;	// For opening animation.
}

-(id)		initWithPart: (Carlson::CPart*)inContainer;

-(void)		setGlobalStartRect: (NSRect)theBox;

@end
