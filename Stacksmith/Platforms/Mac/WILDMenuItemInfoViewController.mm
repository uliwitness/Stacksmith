//
//  WILDMenuItemInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "WILDMenuItemInfoViewController.h"
#include "CMenu.h"


using namespace Carlson;


@interface WILDMenuItemInfoViewController ()
{
	CMenuItem * mMenuItem;
}

@end

@implementation WILDMenuItemInfoViewController

-(id)	initWithConcreteObject: (CConcreteObject*)inObject
{
	self = [super initWithConcreteObject: inObject];
	if( self )
	{
		mMenuItem = dynamic_cast<CMenuItem*>(mInfoedObject);
	}
	return self;
}


-(void) awakeFromNib
{
    [super awakeFromNib];
	
	[_messageField setStringValue: [NSString stringWithUTF8String: mMenuItem->GetMessage().c_str()]];
	[_toolTipField setStringValue: [NSString stringWithUTF8String: mMenuItem->GetToolTip().c_str()]];
	[_keyboardShortcutField setStringValue: [NSString stringWithUTF8String: mMenuItem->GetCommandChar().c_str()]];
	[_markCharacterField setStringValue: [NSString stringWithUTF8String: mMenuItem->GetMarkChar().c_str()]];
	
	_enabledSwitch.state = mMenuItem->GetEnabled() ? NSControlStateValueOn : NSControlStateValueOff;
	_visibleSwitch.state = mMenuItem->GetVisible() ? NSControlStateValueOn : NSControlStateValueOff;
	[_stylePopUp selectItemWithTag: mMenuItem->GetStyle()];
}

-(IBAction)	doStylePopUpChanged: (NSPopUpButton*)sender
{
	mMenuItem->SetStyle((TMenuItemStyle) sender.selectedTag);
}

-(IBAction)	doEnabledSwitchChanged: (NSButton*)sender
{
	mMenuItem->SetEnabled( _enabledSwitch.state == NSControlStateValueOn );
}

-(IBAction)	doVisibleSwitchChanged: (NSButton*)sender
{
	mMenuItem->SetVisible( _visibleSwitch.state == NSControlStateValueOn );
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == _messageField )
	{
		mMenuItem->SetMessage( [_messageField stringValue].UTF8String );
	}
	else if( [notif object] == _toolTipField )
	{
		mMenuItem->SetToolTip( [_toolTipField stringValue].UTF8String );
	}
	else if( [notif object] == _keyboardShortcutField )
	{
		mMenuItem->SetCommandChar( [_keyboardShortcutField stringValue].UTF8String );
	}
	else if( [notif object] == _markCharacterField )
	{
		mMenuItem->SetMarkChar( [_markCharacterField stringValue].UTF8String );
	}
	else
	{
		[super controlTextDidChange: notif];
	}
}

@end
