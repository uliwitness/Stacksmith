//
//  WILDNotifications.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDNotifications.h"


// Peek at button rects:
NSString*	WILDPeekingStateChangedNotification = @"WILDPeekingStateChanged";

NSString*	WILDPeekingStateKey = @"WILDPeekingState";


// Edit the background layer:
NSString*	WILDBackgroundEditModeChangedNotification = @"WILDBackgroundEditModeChanged";

NSString*	WILDBackgroundEditModeKey = @"WILDBackgroundEditMode";


// Change between cards:
NSString*	WILDCurrentCardWillChangeNotification = @"WILDCurrentCardWillChange";
NSString*	WILDCurrentCardDidChangeNotification = @"WILDCurrentCardDidChange";

NSString*	WILDSourceCardKey = @"WILDSourceCard";
NSString*	WILDDestinationCardKey = @"WILDDestinationCard";

// Objects get created/destroyed:
NSString*	WILDLayerDidAddPartNotification = @"WILDLayerDidAddPart";
NSString*	WILDLayerWillRemovePartNotification = @"WILDLayerWillRemovePart";

NSString*	WILDAffectedPartKey = @"WILDAffectedPart";

// Properties of card/background change:
NSString*	WILDLayerWillChangeNotification = @"WILDLayerWillChange";
NSString*	WILDLayerDidChangeNotification = @"WILDLayerDidChange";

// Properties of part change:
NSString*	WILDPartWillChangeNotification = @"WILDPartWillChange";
NSString*	WILDPartDidChangeNotification = @"WILDPartDidChange";

NSString*	WILDAffectedPropertyKey = @"WILDAffectedProperty";


// Properties of stack change:
NSString*	WILDStackWillChangeNotification = @"WILDStackWillChange";
NSString*	WILDStackDidChangeNotification = @"WILDStackDidChange";

//WILDAffectedPropertyKey


// Notifications when the user changes the tool:
NSString*	WILDCurrentToolWillChangeNotification = @"WILDCurrentToolWillChange";
NSString*	WILDCurrentToolDidChangeNotification = @"WILDCurrentToolDidChange";
