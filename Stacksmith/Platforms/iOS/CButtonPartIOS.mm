//
//  CButtonPartIOS.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CButtonPartIOS.h"
#include "CAlert.h"


using namespace Carlson;


@interface WILDButtonActionTarget : NSObject

@property CPart	*	owningPart;

-(void)	triggerMouseUpHandler;

@end


@implementation WILDButtonActionTarget

-(void)	triggerMouseUpHandler
{
	self.owningPart->SendMessage( NULL, [](const char * errMsg, size_t errLineNo, size_t errOffset, CScriptableObject * errObj, bool wasHandled)
	{
		CAlert::RunScriptErrorAlert( errObj, errMsg, errLineNo, errOffset );
	}, EMayGoUnhandled, "mouseUp" );
}

@end


void	CButtonPartIOS::CreateViewIn( UIView * inParentView )
{
	mView = [[UIButton buttonWithType: UIButtonTypeSystem] retain];
	[mView setTitle: [NSString stringWithUTF8String: GetName().c_str()] forState: UIControlStateNormal];
	CGRect box = { { (CGFloat)GetLeft(), (CGFloat)GetTop() }, { (CGFloat)GetRight() - GetLeft(), (CGFloat)GetBottom() - GetTop() } };
	[mView setFrame: box];
	mActionTarget = [WILDButtonActionTarget new];
	mActionTarget.owningPart = this;
	[mView addTarget: mActionTarget action: @selector(triggerMouseUpHandler) forControlEvents: UIControlEventTouchUpInside];
	[inParentView addSubview: mView];
}


void	CButtonPartIOS::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
	[mActionTarget release];
	mActionTarget = nil;
}
