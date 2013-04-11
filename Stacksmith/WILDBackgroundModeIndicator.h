//
//  WILDBackgroundModeIndicator.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDBackgroundModeIndicator : NSObject
{
	
}

+(void)	showOnWindow: (NSWindow*)inWindow;	// If inWindow is NIL, highlights the menu bar.
+(void)	hide;

@end
