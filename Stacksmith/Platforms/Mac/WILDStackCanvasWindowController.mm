//
//  WILDStackCanvasWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-11.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDStackCanvasWindowController.h"
#import "WILDStackCanvasView.h"
#include "CDocument.h"


@interface WILDStackCanvasWindowController ()

@end

@implementation WILDStackCanvasWindowController

-(void)	windowDidLoad
{
    [super windowDidLoad];
	
	self.owningDocument->SaveThumbnailsForOpenStacks();
	
    self.stackCanvasView.owningDocument = self.owningDocument;
	
	NSURL	*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: self.owningDocument->GetURL().c_str()]];
	[self.window setRepresentedURL: theURL];
	[self.window setTitle: theURL.lastPathComponent.stringByDeletingPathExtension];
}

@end
