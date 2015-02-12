//
//  WILDStackCanvasWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2015-02-11.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


namespace Carlson
{
	class CDocument;
}


@class WILDStackCanvasView;


@interface WILDStackCanvasWindowController : NSWindowController

@property (assign,nonatomic) Carlson::CDocument* 			owningDocument;
@property (assign,nonatomic) IBOutlet WILDStackCanvasView*	stackCanvasView;

@end
