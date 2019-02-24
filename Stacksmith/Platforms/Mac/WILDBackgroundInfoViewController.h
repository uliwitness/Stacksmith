//
//  WILDBackgroundInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoViewController.h"
#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CBackground;
}


@interface WILDBackgroundInfoViewController : WILDLayerInfoViewController
{
	
}

-(id)		initWithConcreteObject: (Carlson::CBackground*)inCard;

@end
