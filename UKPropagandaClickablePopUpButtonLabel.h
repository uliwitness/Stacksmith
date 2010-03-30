//
//  UKPropagandaClickablePopUpButtonLabel.h
//  Propaganda
//
//  Created by Uli Kusterer on 27.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKPropagandaClickablePopUpButtonLabel : NSTextField
{
	NSPopUpButton*	mPopUpButton;
}

@property (assign) NSPopUpButton*	popUpButton;

@end
