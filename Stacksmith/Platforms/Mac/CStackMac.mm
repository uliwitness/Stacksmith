//
//  CStackMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStackMac.h"
#import <AppKit/AppKit.h>


using namespace Carlson;


@interface WILDStackWindowController : NSWindowController <NSWindowDelegate>

@end

@implementation WILDStackWindowController

@end


bool	CStackMac::GoThereInNewWindow( bool inNewWindow )
{
	if( !mMacWindowController )
	{
		NSWindow	*	theWindow = [[[NSWindow alloc] initWithContentRect: NSMakeRect(100,100,512,342) styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
		[theWindow setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
		mMacWindowController = [[WILDStackWindowController alloc] initWithWindow: theWindow];
		[theWindow setDelegate: mMacWindowController];
	}
	[mMacWindowController showWindow: nil];
	
	return true;
}