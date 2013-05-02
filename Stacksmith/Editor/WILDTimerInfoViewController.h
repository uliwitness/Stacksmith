//
//  WILDTimerInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"

@interface WILDTimerInfoViewController : WILDPartInfoViewController
{
	NSTextField			*		mMessageField;
	NSTextField			*		mIntervalField;
}

@property (assign) IBOutlet NSTextField*		messageField;
@property (assign) IBOutlet NSTextField*		intervalField;

@end
