//
//  WILDButtonView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

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
