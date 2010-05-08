//
//  WILDTextView.h
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WILDPart;


@interface WILDTextView : NSTextView
{
	WILDPart*	mPart;
}

@property (assign)	WILDPart*	representedPart;

@end
