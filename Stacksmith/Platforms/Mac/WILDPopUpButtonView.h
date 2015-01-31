//
//  WILDPopUpButtonView
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-25.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

namespace Carlson
{
	class CButtonPart;
}


@interface WILDPopUpButtonView : NSPopUpButton
{
	BOOL		lastMouseUpWasInside;
	long		lastButtonNumber;
	NSCursor*	mCursor;
}

@property (assign,nonatomic) Carlson::CButtonPart*	owningPart;

@end
