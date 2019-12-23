//
//  CMessageWatcherMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-17.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMessageWatcherMac.h"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


using namespace Carlson;


@interface WILDMessageWatcherWindowController : NSWindowController

@property (assign,nonatomic) IBOutlet NSTableView	*	messageList;
@property (assign,nonatomic) CMessageWatcherMac		*	messageWatcher;

@end


@implementation WILDMessageWatcherWindowController

-(void)	windowDidLoad
{
	//[self.window setLevel: NSNormalWindowLevel];
	double fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey: @"WILDMessageWatcherFontSize"];
	NSFont * theFont = [NSFont systemFontOfSize: fontSize];
	NSCell * dataCell = _messageList.tableColumns.firstObject.dataCell;
	[dataCell setFont: theFont];
	[_messageList setRowHeight: dataCell.cellSize.height];
}

-(void)	windowWillClose: (NSNotification *)notification
{
	self.messageWatcher->SetVisible(false);
}

-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView;
{
	return self.messageWatcher->GetNumMessages();
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	std::string msg, target;
	self.messageWatcher->GetMessageAtIndex( row, msg, target );
	return [[NSString stringWithUTF8String: msg.c_str()] stringByAppendingFormat: @" (%@)", [NSString stringWithUTF8String: target.c_str()]];
}

@end


CMessageWatcherMac::CMessageWatcherMac()
: mVisible(false)
{
	mMacWindowController = [[WILDMessageWatcherWindowController alloc] initWithWindowNibName: @"WILDMessageWatcherWindowController"];
	mMacWindowController.messageWatcher = this;
	
	[mMacWindowController.window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.3 alpha: 0.7]];
}


CMessageWatcherMac::~CMessageWatcherMac()
{
	[mMacWindowController close];
	[mMacWindowController release];
	mMacWindowController = nil;
}


void	CMessageWatcherMac::AddMessage( const std::string &inMessage, const std::string &inTarget )
{
	NSScrollView	*sv = mMacWindowController.messageList.enclosingScrollView;
	NSRange			visibleRows = [mMacWindowController.messageList rowsInRect: sv.documentVisibleRect];
	BOOL	wasAtBottom = ( (visibleRows.location +visibleRows.length) == mMessages.size() );
	
	CMessageWatcher::AddMessage( inMessage, inTarget );
	
	[mMacWindowController.messageList reloadData];
	
	if( wasAtBottom )
	{
		NSInteger numberOfRows = [mMacWindowController.messageList numberOfRows];

		if (numberOfRows > 0)
			[mMacWindowController.messageList scrollRowToVisible: numberOfRows - 1];
	}
}


bool	CMessageWatcherMac::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		const char*	msgName = [mMacWindowController.window.title UTF8String];
		LEOInitStringValue( outValue, msgName, strlen(msgName), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		NSRect	box = [mMacWindowController.window contentRectForFrameRect: [mMacWindowController.window frame]];
		NSRect	mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		LEOInitRectValue( outValue, NSMinX(box), NSMinY(box), NSMaxX(box), NSMaxY(box), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mVisible, kLEOInvalidateReferences, inContext );
	}
	else
		return CMessageWatcher::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CMessageWatcherMac::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		[mMacWindowController.window setTitle: [NSString stringWithUTF8String: nameStr]];
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		LEOInteger	l, t, r, b;
		LEOGetValueAsRect( inValue, &l, &t, &r, &b, inContext);
		NSRect		box = { { (CGFloat)l, (CGFloat)t }, { (CGFloat)r - l, (CGFloat)b - t } };
		NSRect		mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		
		[mMacWindowController.window setFrame: box display: YES];
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		bool	isVisible = LEOGetValueAsBoolean( inValue, inContext );
		if( isVisible )
			[mMacWindowController.window makeKeyAndOrderFront: nil];
		else
			[mMacWindowController.window orderOut: nil];
		mVisible = isVisible;
	}
	else
		return CMessageWatcher::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CMessageWatcherMac::SetVisible( bool n )
{
	if( n )
		[mMacWindowController.window makeKeyAndOrderFront: nil];
	else
		[mMacWindowController.window orderOut: nil];
	mVisible = n;
}


