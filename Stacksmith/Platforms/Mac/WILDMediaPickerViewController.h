//
//  WILDMediaPickerViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDMediaListDataSource.h"

namespace Carlson
{
	class CButtonPart;
}


@interface WILDMediaPickerViewController : NSViewController <WILDMediaListDataSourceDelegate>
{
	WILDMediaListDataSource	*iconListDataSource;
	Carlson::CButtonPart	*part;
}

@property (assign) IBOutlet WILDMediaListDataSource *iconListDataSource;
@property (assign,nonatomic) Carlson::TMediaType	mediaType;

-(id)	initWithPart: (Carlson::CButtonPart*)inPart;

@end
