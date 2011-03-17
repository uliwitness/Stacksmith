//
//  WILDPresentationConstants.h
//  Stacksmith
//
//  Created by Uli Kusterer on 08.05.10.
//  Copyright 2010 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// The type under which we put parts on the drag/copy pasteboard:
//	This contains an NSString of XML describing the part(s) copied/dragged.
extern NSString*	WILDPartPboardType;


// The type under which we put cards on the drag/copy pasteboard:
//	This contains an NSString of XML describing the card copied/dragged.
extern NSString*	WILDCardPboardType;


// The type under which we put backgrounds on the drag/copy pasteboard:
//	This contains an NSString of XML describing the background copied/dragged.
extern NSString*	WILDBackgroundPboardType;