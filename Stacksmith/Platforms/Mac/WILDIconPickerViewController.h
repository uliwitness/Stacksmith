//
//  WILDIconPickerViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDIconListDataSource.h"

namespace Carlson
{
	class CButtonPart;
}


@interface WILDIconPickerViewController : NSViewController <WILDIconListDataSourceDelegate>
{
	WILDIconListDataSource	*iconListDataSource;
	Carlson::CButtonPart	*part;
}

@property (assign) IBOutlet WILDIconListDataSource *iconListDataSource;

-(id)	initWithPart: (Carlson::CButtonPart*)inPart;

@end
