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
	CAutoreleasePool autoreleasePool;
	
	self.owningPart->SendMessage( NULL, [](const char * errMsg, size_t errLineNo, size_t errOffset, CScriptableObject * errObj, bool wasHandled)
	{
		CAlert::RunScriptErrorAlert( errObj, errMsg, errLineNo, errOffset );
	}, EMayGoUnhandled, "mouseUp" );
}


-(void)	triggerMouseDownHandler
{
	CAutoreleasePool autoreleasePool;
	
	self.owningPart->SendMessage( NULL, [](const char * errMsg, size_t errLineNo, size_t errOffset, CScriptableObject * errObj, bool wasHandled)
								 {
									 CAlert::RunScriptErrorAlert( errObj, errMsg, errLineNo, errOffset );
								 }, EMayGoUnhandled, "mouseDown" );
}

@end


void	CButtonPartIOS::CreateViewIn( UIView * inParentView )
{
	if( !mActionTarget )
	{
		mActionTarget = [WILDButtonActionTarget new];
		mActionTarget.owningPart = this;
	}
	if( mButtonStyle == EButtonStyleCheckBox || mButtonStyle == EButtonStyleRadioButton )
	{
		mView = [[UISwitch alloc] initWithFrame: CGRectZero];
		[inParentView addSubview: mView];
		[(UISwitch*)mView setOn: mHighlight != false];
		[mView addTarget: mActionTarget action: @selector(triggerMouseUpHandler) forControlEvents: UIControlEventTouchUpInside];
		[mView addTarget: mActionTarget action: @selector(triggerMouseDownHandler) forControlEvents: UIControlEventTouchDown];
	}
	else
	{
		mView = [[UIButton buttonWithType: UIButtonTypeSystem] retain];
		[inParentView addSubview: mView];
		[(UIButton*)mView setTitle: [NSString stringWithUTF8String: GetName().c_str()] forState: UIControlStateNormal];
		[mView addTarget: mActionTarget action: @selector(triggerMouseUpHandler) forControlEvents: UIControlEventTouchUpInside];
		[mView addTarget: mActionTarget action: @selector(triggerMouseDownHandler) forControlEvents: UIControlEventTouchDown];
	}
	mView.translatesAutoresizingMaskIntoConstraints = NO;
	switch( PART_H_LAYOUT_MODE(mPartLayoutFlags) )
	{
		case EPartLayoutAlignHCenter:
			[mView.centerXAnchor constraintEqualToAnchor: inParentView.centerXAnchor].active = YES;
			[mView.widthAnchor constraintEqualToConstant: mRight -mLeft].active = YES;
			break;
		case EPartLayoutAlignLeft:
			[mView.leftAnchor constraintEqualToAnchor: inParentView.leftAnchor constant: mLeft].active = YES;
			[mView.widthAnchor constraintEqualToConstant: mRight -mLeft].active = YES;
			break;
		case EPartLayoutAlignRight:
			[mView.rightAnchor constraintEqualToAnchor: inParentView.rightAnchor constant: -mRight].active = YES;
			[mView.widthAnchor constraintEqualToConstant: -(mRight -mLeft)].active = YES;
			break;
		case EPartLayoutAlignHBoth:
			[mView.leftAnchor constraintEqualToAnchor: inParentView.leftAnchor constant: mLeft].active = YES;
			[mView.rightAnchor constraintEqualToAnchor: inParentView.rightAnchor constant: -mRight].active = YES;
			break;
	}
	switch( PART_V_LAYOUT_MODE(mPartLayoutFlags) )
	{
		case EPartLayoutAlignVCenter:
			[mView.centerYAnchor constraintEqualToAnchor: inParentView.centerYAnchor].active = YES;
			[mView.heightAnchor constraintEqualToConstant: mBottom -mTop].active = YES;
			break;
		case EPartLayoutAlignTop:
			[mView.topAnchor constraintEqualToAnchor: inParentView.topAnchor constant: mTop].active = YES;
			[mView.heightAnchor constraintEqualToConstant: mBottom -mTop].active = YES;
			break;
		case EPartLayoutAlignBottom:
			[mView.bottomAnchor constraintEqualToAnchor: inParentView.bottomAnchor constant: -mBottom].active = YES;
			[mView.heightAnchor constraintEqualToConstant: -(mBottom -mTop)].active = YES;
			break;
		case EPartLayoutAlignVBoth:
			[mView.topAnchor constraintEqualToAnchor: inParentView.topAnchor constant: mTop].active = YES;
			[mView.bottomAnchor constraintEqualToAnchor: inParentView.bottomAnchor constant: -mBottom].active = YES;
			break;
	}
}


void	CButtonPartIOS::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
	[mActionTarget release];
	mActionTarget = nil;
}


void	CButtonPartIOS::SetHighlight( bool inState )
{
	if( mButtonStyle == EButtonStyleCheckBox || mButtonStyle == EButtonStyleRadioButton )
	{
		[(UISwitch*)mView setOn: inState != false];
	}
	CButtonPart::SetHighlight(inState);
}
