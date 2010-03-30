//
//  UKPropagandaNotifications.h
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
// Notification sent when user holds down or releases the Cmd-Option key
//	combination:
NSString*	UKPropagandaPeekingStateChangedNotification;

// Info dictionary keys:
NSString*	UKPropagandaPeekingStateKey;


// -----------------------------------------------------------------------------
// Notification sent when user chooses the "Background" menu item to edit the
//	background alone:
NSString*	UKPropagandaBackgroundEditModeChangedNotification;

// Info dictionary keys:
NSString*	UKPropagandaBackgroundEditModeKey;


// -----------------------------------------------------------------------------
// Notifications when we change between cards:
NSString*	UKPropagandaCurrentCardWillChangeNotification;	// We're on the source card.
NSString*	UKPropagandaCurrentCardDidChangeNotification;	// We're on the destination card.

// Info dictionary keys:
NSString*	UKPropagandaSourceCardKey;		// May be missing (e.g. when loading the first card after opening a stack window).
NSString*	UKPropagandaDestinationCardKey;	// May be missing (e.g. when closing a stack).


// -----------------------------------------------------------------------------
// Notifications when we change properties of parts:
NSString*	UKPropagandaPartWillChangeNotification;	// Part has old state.
NSString*	UKPropagandaPartDidChangeNotification;	// Part has new state.

// Info dictionary keys:
NSString*	UKPropagandaAffectedPropertyKey;
