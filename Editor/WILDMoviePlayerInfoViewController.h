//
//  WILDMoviePlayerInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartInfoViewController.h"

@interface WILDMoviePlayerInfoViewController : WILDPartInfoViewController
{
	NSTextField			*		mMoviePathField;
}

@property (retain) IBOutlet NSTextField*		moviePathField;

-(IBAction)	doChooseMovieFile: (id)sender;

@end
