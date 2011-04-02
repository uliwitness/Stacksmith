//
//  WILDNotifications.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
// Notification sent when user holds down or releases the Cmd-Option key
//	combination:
extern NSString*	WILDPeekingStateChangedNotification;

// Info dictionary keys:
extern NSString*	WILDPeekingStateKey;


// -----------------------------------------------------------------------------
// Notification sent when user chooses the "Background" menu item to edit the
//	background alone:
extern NSString*	WILDBackgroundEditModeChangedNotification;

// Info dictionary keys:
extern NSString*	WILDBackgroundEditModeKey;


// -----------------------------------------------------------------------------
// Notifications when we change between cards:
extern NSString*	WILDCurrentCardWillChangeNotification;	// We're on the source card.
extern NSString*	WILDCurrentCardDidChangeNotification;	// We're on the destination card.

// Info dictionary keys:
extern NSString*	WILDSourceCardKey;		// May be missing (e.g. when loading the first card after opening a stack window).
extern NSString*	WILDDestinationCardKey;	// May be missing (e.g. when closing a stack).


// -----------------------------------------------------------------------------
// Notifications when parts are created/destroyed (by the user, not just due to
//	the document being closed or the app being quit):
// Objects get created/destroyed:
extern NSString*	WILDLayerDidAddPartNotification;
extern NSString*	WILDLayerWillRemovePartNotification;

// Info dictionary key:
extern NSString*	WILDAffectedPartKey;	// The part that was added to the layer that is our sender.


// -----------------------------------------------------------------------------
// Notifications when we change properties of parts:
extern NSString*	WILDPartWillChangeNotification;	// Part has old state.
extern NSString*	WILDPartDidChangeNotification;	// Part has new state.

// Info dictionary keys:
extern NSString*	WILDAffectedPropertyKey;	// Property on the WILDPart, not the xTalk property name.


// -----------------------------------------------------------------------------
// Notifications when we change properties of stacks:

extern NSString*	WILDStackWillChangeNotification;
extern NSString*	WILDStackDidChangeNotification;

// Info dictionary keys:
//					WILDAffectedPropertyKey


// -----------------------------------------------------------------------------
// Notifications when the user changes the tool:
extern NSString*	WILDCurrentToolWillChangeNotification;
extern NSString*	WILDCurrentToolDidChangeNotification;

