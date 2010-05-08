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
NSString*	WILDPeekingStateChangedNotification;

// Info dictionary keys:
NSString*	WILDPeekingStateKey;


// -----------------------------------------------------------------------------
// Notification sent when user chooses the "Background" menu item to edit the
//	background alone:
NSString*	WILDBackgroundEditModeChangedNotification;

// Info dictionary keys:
NSString*	WILDBackgroundEditModeKey;


// -----------------------------------------------------------------------------
// Notifications when we change between cards:
NSString*	WILDCurrentCardWillChangeNotification;	// We're on the source card.
NSString*	WILDCurrentCardDidChangeNotification;	// We're on the destination card.

// Info dictionary keys:
NSString*	WILDSourceCardKey;		// May be missing (e.g. when loading the first card after opening a stack window).
NSString*	WILDDestinationCardKey;	// May be missing (e.g. when closing a stack).


// -----------------------------------------------------------------------------
// Notifications when we change properties of parts:
NSString*	WILDPartWillChangeNotification;	// Part has old state.
NSString*	WILDPartDidChangeNotification;	// Part has new state.

// Info dictionary keys:
NSString*	WILDAffectedPropertyKey;	// Property on the WILDPart, not the xTalk property name.


// -----------------------------------------------------------------------------
// Notifications when the user changes the tool:
NSString*	WILDCurrentToolWillChangeNotification;
NSString*	WILDCurrentToolDidChangeNotification;

