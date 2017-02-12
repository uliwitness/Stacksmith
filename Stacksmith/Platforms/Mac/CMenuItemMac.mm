//
//  CMenuItemMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 12/02/17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CMenuItemMac.h"
#import "WILDMenuItemInfoViewController.h"


using namespace Carlson;


WILDNSImagePtr	CMenuItemMac::GetDisplayIcon()
{
	return [NSImage imageNamed: @"MenuItemIconSmall"];
}


Class	CMenuItemMac::GetPropertyEditorClass()
{
	return [WILDMenuItemInfoViewController class];
}
