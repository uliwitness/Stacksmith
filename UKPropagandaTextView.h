//
//  UKPropagandaTextView.h
//  Propaganda
//
//  Created by Uli Kusterer on 25.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UKPropagandaPart;


@interface UKPropagandaTextView : NSTextView
{
	UKPropagandaPart*	mPart;
}

@property (assign)	UKPropagandaPart*	representedPart;

@end
