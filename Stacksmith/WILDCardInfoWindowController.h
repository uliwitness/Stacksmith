//
//  WILDCardInfoWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoWindowController.h"
#import <Cocoa/Cocoa.h>


@class WILDCardView;
@class WILDCard;


@interface WILDCardInfoWindowController : WILDLayerInfoWindowController
{
	NSButton		*	mMarkedSwitch;
}

@property (retain) IBOutlet	NSButton		*	markedSwitch;

-(id)		initWithCard: (WILDCard*)inCard ofCardView: (WILDCardView*)owningView;

@end
