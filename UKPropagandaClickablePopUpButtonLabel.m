//
//  UKPropagandaClickablePopUpButtonLabel.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaClickablePopUpButtonLabel.h"


@implementation UKPropagandaClickablePopUpButtonLabel

@synthesize popUpButton = mPopUpButton;

-(void)	mouseDown: (NSEvent*)evt
{
    [[mPopUpButton cell] performClickWithFrame: [mPopUpButton bounds] inView: mPopUpButton];
}

@end
