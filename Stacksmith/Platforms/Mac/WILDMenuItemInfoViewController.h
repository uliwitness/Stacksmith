//
//  WILDMenuItemInfoViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "WILDConcreteObjectInfoViewController.h"

@interface WILDMenuItemInfoViewController : WILDConcreteObjectInfoViewController

@property (assign) IBOutlet NSPopUpButton *stylePopUp;
@property (assign) IBOutlet NSButton *enabledSwitch;
@property (assign) IBOutlet NSButton *visibleSwitch;
@property (assign) IBOutlet NSTextField *messageField;
@property (assign) IBOutlet NSTextField *toolTipField;
@property (assign) IBOutlet NSTextField *keyboardShortcutField;
@property (assign) IBOutlet NSTextField *markCharacterField;

-(IBAction)	doStylePopUpChanged: (NSPopUpButton*)sender;
-(IBAction)	doEnabledSwitchChanged: (NSButton*)sender;
-(IBAction)	doVisibleSwitchChanged: (NSButton*)sender;

@end
