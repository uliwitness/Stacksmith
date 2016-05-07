//
//  WILDButtonView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

/*
	A button class that, instead of sending only a Cocoa message to the target
	on mouseUp, will actually call all the mouse tracking handlers in the owning
	part's script. Do not set a traditional Cocoa target/action on this button.
	On a return key press for a default button, this also sends "mouseUp".
*/

#import <Cocoa/Cocoa.h>
#if __cplusplus
#import "CButtonPart.h"
#endif

@interface WILDButtonView : NSButton
{
	NSTrackingArea	*	mCursorTrackingArea;
	NSCursor*			mCursor;
}

#if __cplusplus
@property (assign,nonatomic) Carlson::CButtonPart*	owningPart;
#endif

-(void)	reloadCursor;

@end
