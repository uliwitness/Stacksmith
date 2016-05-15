//
//  WILDInspectorWindowController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 15/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDInspectorWindowController : NSWindowController

+(WILDInspectorWindowController*)	sharedInspectorWindowController;

-(IBAction)	makeKeyAndOrderFront: (id)sender;

@end
