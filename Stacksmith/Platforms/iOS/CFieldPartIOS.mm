//
//  CFieldPartIOS.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#include "CFieldPartIOS.h"
#include "CAlert.h"
#include "CPartContents.h"
#include "UTF8UTF32Utilities.h"


using namespace Carlson;


@interface WILDFieldActionTarget : NSObject

@property CPart	*	owningPart;

-(void)	triggerMouseUpHandler;

@end


@implementation WILDFieldActionTarget

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


void	CFieldPartIOS::CreateViewIn( UIView * inParentView )
{
	if( !mActionTarget )
	{
		mActionTarget = [WILDFieldActionTarget new];
		mActionTarget.owningPart = this;
	}
	mView = [[UITextField alloc] initWithFrame: CGRectZero];
	[inParentView addSubview: mView];
	[(UITextField*)mView setText: [NSString stringWithUTF8String: GetContentsOnCurrentCard()->GetText().c_str()]];
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


void	CFieldPartIOS::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
	[mActionTarget release];
	mActionTarget = nil;
}


/*static*/ size_t	CFieldPartIOS::UTF8OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr )
{
	NSInteger	currOffs = 0;
	size_t		currUTF8Offs = 0;
	
	if( inCharOffs == 0 )
		return 0;
	
	NSInteger	strLen = [cocoaStr length];
	
	while( currOffs < strLen )
	{
		size_t	remainingLen = strLen -currOffs;
		unichar	currCh = [cocoaStr characterAtIndex: currOffs];
		
		if( remainingLen < 2 || currCh < 0xD800 || currCh > 0xDBFF )
		{
			currOffs += 1;
			currUTF8Offs += UTF8LengthForUTF32Char(currCh);
		}
		else
		{
			currUTF8Offs += UTF8LengthForUTF32Char( (currCh -0xD800) * 0x400 +([cocoaStr characterAtIndex: currOffs +1] -0xDC00) + 0x10000 );
			currOffs += 2;
		}
		
		if( currOffs >= inCharOffs )
			break;
	}
	
	return currUTF8Offs;
}


/*static*/ size_t	CFieldPartIOS::UTF32OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr )
{
	NSInteger	currOffs = 0;
	size_t		currUTF32Offs = 0;
	
	if( inCharOffs == 0 )
		return 0;
	
	NSInteger	strLen = [cocoaStr length];
	
	while( currOffs < strLen )
	{
		size_t	remainingLen = strLen -currOffs;
		unichar	currCh = [cocoaStr characterAtIndex: currOffs];
	
		if( remainingLen < 1 )
			;
		else if( remainingLen < 2 || currCh < 0xD800 || currCh > 0xDBFF )
		{
			currOffs += 1;
			currUTF32Offs += 1;
		}
		else
		{
			currOffs += 2;
			currUTF32Offs += 1;
		}
		
		if( currOffs >= inCharOffs )
			break;
	}
	
	return currUTF32Offs;
}


/*static*/ NSInteger	CFieldPartIOS::UTF16OffsetFromUTF32OffsetInCocoaString( size_t inUTF32Offs, NSString* cocoaStr )
{
	NSInteger	currUTF16Offs = 0;
	size_t		currUTF32Offs = 0;
	
	if( inUTF32Offs == 0 )
		return 0;
	
	NSInteger	strLen = [cocoaStr length];
	
	while( currUTF16Offs < strLen )
	{
		size_t	remainingLen = strLen -currUTF16Offs;
		unichar	currCh = [cocoaStr characterAtIndex: currUTF16Offs];
	
		if( remainingLen < 1 )
			;
		else if( remainingLen < 2 || currCh < 0xD800 || currCh > 0xDBFF )
		{
			currUTF16Offs += 1;
			currUTF32Offs += 1;
		}
		else
		{
			currUTF16Offs += 2;
			currUTF32Offs += 1;
		}
		
		if( currUTF32Offs >= inUTF32Offs )
			break;
	}
	
	return currUTF16Offs;
}


void	CFieldPartIOS::SetSelectedRange( LEOChunkType inType, size_t inStartOffs, size_t inEndOffs )
{
	if( inEndOffs < inStartOffs )
	{
		NSInteger selStart = 0;
		if( mView.text.length > 0 )
			selStart = mView.text.length -1;
		//[mView setSelectedRange: NSMakeRange(selStart,0)];
	}
	else
	{
		NSRange	cocoaRange;
		cocoaRange.location = UTF16OffsetFromUTF32OffsetInCocoaString( inStartOffs -1, mView.text );
		cocoaRange.length = UTF16OffsetFromUTF32OffsetInCocoaString( inEndOffs -1, mView.text ) +1 -cocoaRange.location;
		//[mView setSelectedRange: cocoaRange];
	}
}


void	CFieldPartIOS::GetSelectedRange( LEOChunkType* outType, size_t* outStartOffs, size_t* outEndOffs )
{
	NSRange	selRange = { 0, 0 }; //[mView selectedRange];
	*outStartOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location, mView.text ) +1;
	*outEndOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location +selRange.length, mView.text );
	*outType = kLEOChunkTypeCharacter;
}
