//
//  UKPropagandaNotifications.m
//  Propaganda
//
//  Created by Uli Kusterer on 20.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaNotifications.h"


// Peek at button rects:
NSString*	UKPropagandaPeekingStateChangedNotification = @"UKPropagandaPeekingStateChanged";

NSString*	UKPropagandaPeekingStateKey = @"UKPropagandaPeekingState";


// Edit the background layer:
NSString*	UKPropagandaBackgroundEditModeChangedNotification = @"UKPropagandaBackgroundEditModeChanged";

NSString*	UKPropagandaBackgroundEditModeKey = @"UKPropagandaBackgroundEditMode";


// Change between cards:
NSString*	UKPropagandaCurrentCardWillChangeNotification = @"UKPropagandaCurrentCardWillChange";
NSString*	UKPropagandaCurrentCardDidChangeNotification = @"UKPropagandaCurrentCardDidChange";

NSString*	UKPropagandaSourceCardKey = @"UKPropagandaSourceCard";
NSString*	UKPropagandaDestinationCardKey = @"UKPropagandaDestinationCard";


// Properties of part change:
NSString*	UKPropagandaPartWillChangeNotification = @"UKPropagandaPartWillChange";
NSString*	UKPropagandaPartDidChangeNotification = @"UKPropagandaPartDidChange";

NSString*	UKPropagandaAffectedPropertyKey = @"UKPropagandaAffectedProperty";


// Notifications when the user changes the tool:
NSString*	UKPropagandaCurrentToolWillChangeNotification = @"UKPropagandaCurrentToolWillChange";
NSString*	UKPropagandaCurrentToolDidChangeNotification = @"UKPropagandaCurrentToolDidChange";
