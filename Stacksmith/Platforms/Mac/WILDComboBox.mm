//
//  WILDComboBox.m
//  Stacksmith
//
//  Created by Uli Kusterer on 14/02/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import "WILDComboBox.h"
#import "UKHelperMacros.h"
#import "UKPushbackMessenger.h"
#include "CFieldPartMac.h"
#include "CAlert.h"


using namespace Carlson;


@implementation WILDComboBox

@synthesize owningField;
@synthesize dontSendSelectionChange;
@synthesize selectedRange;

-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSTextViewDidChangeSelectionNotification object: nil];
	DESTROY_DEALLOC(pushbackMessenger);
	
	[super dealloc];
}


-(void)	beginWatchingForSelectionChanges
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(fieldEditorsSelectionDidChange:) name: NSTextViewDidChangeSelectionNotification object: nil];
}


-(void)	fieldEditorsSelectionDidChange: (NSNotification *)notif
{
	NSText*	fieldEditor = notif.object;
	if( fieldEditor != self.currentEditor || self.dontSendSelectionChange )
		return;
	
	if( !pushbackMessenger )
	{
		pushbackMessenger = [[UKPushbackMessenger alloc] initWithTarget: self];
		[pushbackMessenger setDelay: 0.1];
		[pushbackMessenger setMaxPushTime: 0.5];
	}
	[(id)pushbackMessenger sendSelectionChangeMessage];
}


-(void)	sendSelectionChangeMessage
{
	if( self.currentEditor.selectedRange.location != selectedRange.location || self.currentEditor.selectedRange.length != selectedRange.length )
	{
		selectedRange = self.currentEditor.selectedRange;
		
		CAutoreleasePool		pool;
		self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "selectionChange" );
	}
}


-(void)	setSelectedRange: (NSRange)inRange
{
	selectedRange = inRange;
	[self.currentEditor setSelectedRange: inRange];
}

@end;
