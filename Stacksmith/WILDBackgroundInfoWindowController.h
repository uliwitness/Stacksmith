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
@class WILDBackground;


@interface WILDBackgroundInfoWindowController : WILDLayerInfoWindowController
{
	
}

-(id)		initWithBackground: (WILDBackground*)inCard ofCardView: (WILDCardView*)owningView;

@end
