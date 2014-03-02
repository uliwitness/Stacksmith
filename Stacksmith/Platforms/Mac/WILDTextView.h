//
//  WILDTextView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "CFieldPart.h"


@interface WILDTextView : NSTextView

@property (assign) Carlson::CFieldPart*	owningPart;

@end
