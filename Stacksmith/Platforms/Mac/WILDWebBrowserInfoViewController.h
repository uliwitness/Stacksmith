//
//  WILDWebBrowserInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"

@interface WILDWebBrowserInfoViewController : WILDPartInfoViewController
{
	NSTextField			*		mCurrentURLField;
}

@property (assign) IBOutlet NSTextField*		currentURLField;

@end
