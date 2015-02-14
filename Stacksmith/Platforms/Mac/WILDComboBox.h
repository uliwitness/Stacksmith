//
//  WILDComboBox.h
//  Stacksmith
//
//  Created by Uli Kusterer on 14/02/15.
//  Copyright (c) 2015 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

namespace Carlson
{
class CFieldPartMac;
}

@class UKPushbackMessenger;


@interface WILDComboBox : NSComboBox
{
	UKPushbackMessenger	*	pushbackMessenger;
}

@property (assign,nonatomic) Carlson::CFieldPartMac*owningField;
@property (assign,nonatomic) BOOL					dontSendSelectionChange;
@property (assign,nonatomic) NSRange				selectedRange;

@end
