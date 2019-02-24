//
//  WILDCardInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoViewController.h"
#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CCard;
}


@interface WILDCardInfoViewController : WILDLayerInfoViewController
{
	NSButton		*	mMarkedSwitch;
}

@property (retain) IBOutlet	NSButton		*	markedSwitch;

-(id)		initWithConcreteObject: (Carlson::CCard*)inCard;

-(IBAction)	doMarkedSwitchChanged: (id)sender;

@end
