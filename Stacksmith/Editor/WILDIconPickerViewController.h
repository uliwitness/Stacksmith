//
//  WILDIconPickerViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDIconListDataSource.h"


@class WILDPart;


@interface WILDIconPickerViewController : NSViewController <WILDIconListDataSourceDelegate>
{
	WILDIconListDataSource	*iconListDataSource;
	WILDPart				*part;
}

@property (assign) IBOutlet WILDIconListDataSource *iconListDataSource;

@end
