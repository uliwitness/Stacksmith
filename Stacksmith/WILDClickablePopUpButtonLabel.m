//
//  WILDClickablePopUpButtonLabel.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDClickablePopUpButtonLabel.h"


@implementation WILDClickablePopUpButtonLabel

@synthesize popUpButton = mPopUpButton;

-(void)	mouseDown: (NSEvent*)evt
{
    [[mPopUpButton cell] performClickWithFrame: [mPopUpButton bounds] inView: mPopUpButton];
}

@end
