//
//  WILDBackgroundInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoViewController.h"
#import <Cocoa/Cocoa.h>


@class WILDCardView;
@class WILDBackground;


@interface WILDBackgroundInfoViewController : WILDLayerInfoViewController
{
	
}

-(id)		initWithBackground: (WILDBackground*)inCard ofCardView: (WILDCardView*)owningView;

@end
