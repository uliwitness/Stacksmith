//
//  WILDPictureView.h
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDPictureView : NSView
{
	NSImage*	image;
}

-(NSImage*)	image;
-(void)		setImage: (NSImage*)theImage;

@end
