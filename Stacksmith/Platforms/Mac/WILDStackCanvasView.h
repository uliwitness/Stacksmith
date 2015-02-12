//
//  WILDStackCanvasView.h
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

@interface WILDStackCanvasView : NSView

@property (assign,nonatomic) Carlson::CDocument* owningDocument;

@end
