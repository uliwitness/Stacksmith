//
//  WILDButtonView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 09.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CButtonPart.h"


@interface WILDButtonView : NSButton
{
	NSTrackingArea	*	mCursorTrackingArea;
}

@property (assign,nonatomic) Carlson::CButtonPart*	owningPart;

@end
