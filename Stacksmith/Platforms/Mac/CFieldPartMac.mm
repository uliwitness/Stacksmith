//
//  CFieldPartMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CFieldPartMac.h"
#include "CPartContents.h"
#import "WILDViewFactory.h"
#import "CAlert.h"
#include "CStack.h"
#include "UTF8UTF32Utilities.h"


using namespace Carlson;


@interface WILDFieldDelegate : NSObject <NSTextViewDelegate,NSTableViewDelegate, NSTableViewDataSource>

@property (assign,nonatomic) CFieldPartMac*	owningField;
@property (retain,nonatomic) NSArray*		lines;

@end

@implementation WILDFieldDelegate

-(void)	dealloc
{
	self.lines = nil;
	
	[super dealloc];
}


-(void)	textDidChange: (NSNotification *)obj
{
	self.owningField->SetViewTextNeedsSync( true );
//	NSLog( @"Edited text." );
}


-(void)	textViewDidChangeTypingAttributes: (NSNotification *)notification
{
	self.owningField->SetViewTextNeedsSync( true );
//	NSLog( @"Edited styles or so." );
}


-(BOOL)	textView: (NSTextView *)textView clickedOnLink: (id)link atIndex: (NSUInteger)charIndex
{
	NSURL*	theLink = [textView.textStorage attribute: NSLinkAttributeName atIndex: charIndex effectiveRange:NULL];
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUpInLink %s", [[theLink absoluteString] UTF8String] );
	
	return YES;
}


-(void)	textViewDidChangeSelection: (NSNotification *)notification
{
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	return [self.lines count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	return [self.lines objectAtIndex: row];
}


-(void)	tableViewSelectionDidChange:(NSNotification *)notification
{
	self.owningField->ClearSelectedLines();
	NSIndexSet	*	selRows = [[notification object] selectedRowIndexes];
	NSInteger idx = [selRows firstIndex];
	while( idx != NSNotFound )
	{
		self.owningField->AddSelectedLine( idx +1 );
		
		idx = [selRows indexGreaterThanIndex: idx];
	}
	
	CAutoreleasePool	cppPool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
}

-(BOOL)	tableView: (NSTableView *)tableView shouldEditTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	return !self.owningField->GetLockText();
}


-(void)	tableViewRowClicked: (id)sender
{
	CAutoreleasePool	cppPool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUp" );
//	NSLog(@"tableViewRowClicked");
}


-(void)	tableViewRowDoubleClicked: (id)sender
{
	CAutoreleasePool	cppPool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseDoubleClick" );
//	NSLog(@"tableViewRowDoubleClicked");
	if( !self.owningField->GetLockText() )
	{
		NSInteger	currRow = [sender clickedRow];
		NSInteger	currColumn = [sender clickedColumn];
		[sender editColumn: currColumn row: currRow withEvent: nil select: YES];
	}
}

@end;

struct ListChunkCallbackContext
{
	NSMutableArray	*	lines;
	CPartContents	*	contents;
	NSDictionary	*	defaultAttrs;
};


static bool	ListChunkCallback( const char* currStr, size_t currLen, size_t currStart, size_t currEnd, void* userData )
{
	ListChunkCallbackContext*	context = (ListChunkCallbackContext*)userData;
	NSAttributedString		*	itemTitle = CFieldPartMac::GetCocoaAttributedString( context->contents->GetAttributedText(), context->defaultAttrs, currStart, currEnd );
	[context->lines addObject: itemTitle];
		
	return true;
}


CFieldPartMac::CFieldPartMac( CLayer *inOwner )
	: CFieldPart( inOwner ), mView(nil), mMacDelegate(nil), mTableView(nil), mTextView(nil)
{
	
}


void	CFieldPartMac::DestroyView()
{
	[mView removeFromSuperview];
	[mView release];
	mView = nil;
	[mMacDelegate release];
	mMacDelegate = nil;
}



void	CFieldPartMac::CreateViewIn( NSView* inSuperView )
{
	if( mView.superview == inSuperView )
	{
		[mView removeFromSuperview];
		[inSuperView addSubview: mView];	// Make sure we show up in right layering order.
		return;
	}
	mMacDelegate = [[WILDFieldDelegate alloc] init];
	mMacDelegate.owningField = this;
	if( mAutoSelect )
	{
		mTableView = [WILDViewFactory tableViewInContainer];
		mTableView.dataSource = mMacDelegate;
		mTableView.delegate = mMacDelegate;
		[mTableView setTarget: mMacDelegate];
		[mTableView setAction: @selector(tableViewRowClicked:)];
		[mTableView setDoubleAction: @selector(tableViewRowDoubleClicked:)];
		mView = (WILDScrollView*) [[mTableView enclosingScrollView] retain];
	}
	else
	{
		mTextView = [WILDViewFactory textViewInContainer];
		mTextView.delegate = mMacDelegate;
		mView = (WILDScrollView*) [[mTextView enclosingScrollView] retain];
		[mTextView setDrawsBackground: NO];
		[mTextView setBackgroundColor: [NSColor clearColor]];
	}
	[mView setBackgroundColor: [NSColor colorWithCalibratedRed: (mFillColorRed / 65535.0) green: (mFillColorGreen / 65535.0) blue: (mFillColorBlue / 65535.0) alpha:(mFillColorAlpha / 65535.0)]];
	[mView setHasHorizontalScroller: mHasHorizontalScroller != false];
	[mView setHasVerticalScroller: mHasVerticalScroller != false];
	if( mFieldStyle == EFieldStyleTransparent )
	{
		[mView setBorderType: NSNoBorder];
		[mView setBackgroundColor: [NSColor clearColor]];
	}
	else if( mFieldStyle == EFieldStyleOpaque )
		[mView setBorderType: NSNoBorder];
	else if( mFieldStyle == EFieldStyleRectangle )
	{
		[mView setBorderType: NSLineBorder];
		[mView setLineColor: [NSColor colorWithCalibratedRed: (mLineColorRed / 65535.0) green: (mLineColorGreen / 65535.0) blue: (mLineColorBlue / 65535.0) alpha:(mLineColorAlpha / 65535.0)]];
		[mView setLineWidth: mLineWidth];
	}
	if( mAutoSelect )
	{
		LoadChangedTextStylesIntoView();
		[mTableView.tableColumns[0] setEditable: !GetLockText()];
		[mTableView deselectAll: nil];
		std::set<size_t>	selLines = mSelectedLines;
		for( size_t currLine : selLines )
		{
			[mTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: currLine -1] byExtendingSelection: YES];
		}
	}
	else
	{
		CPartContents*	contents = GetContentsOnCurrentCard();
		if( contents )
		{
			CAttributedString&		cppstr = contents->GetAttributedText();
			NSAttributedString*		attrStr = GetCocoaAttributedString( cppstr, GetCocoaAttributesForPart() );
			bool					oldRTF = cppstr.GetString().find("{\\rtf1\\ansi\\") == 0;
			if( oldRTF )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
			{
				NSDictionary*	docAttrs = nil;
				attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: cppstr.GetString().c_str() length: cppstr.GetLength()] documentAttributes: &docAttrs];
			}
			[mTextView.textStorage setAttributedString: attrStr];
			if( oldRTF )
				SetAttributedStringWithCocoa( cppstr, attrStr );	// Save the parsed RTF back as something the cross-platform code understands.
		}
		else
			[mTextView setString: @""];
		[mTextView setEditable: !GetLockText() && GetEnabled()];
		[mTextView setSelectable: !GetLockText()];
	}
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


void	CFieldPartMac::SetHasHorizontalScroller( bool inHS )
{
	CFieldPart::SetHasHorizontalScroller(inHS);
	[mView setHasHorizontalScroller: inHS != false];
}


void	CFieldPartMac::SetHasVerticalScroller( bool inHS )
{
	CFieldPart::SetHasVerticalScroller(inHS);
	[mView setHasVerticalScroller: inHS != false];
}


void	CFieldPartMac::SetStyle( TFieldStyle inFieldStyle )
{
	NSView*	oldSuper = mView.superview;
	DestroyView();
	CFieldPart::SetStyle(inFieldStyle);
	if( oldSuper )
		CreateViewIn( oldSuper );
}


void	CFieldPartMac::SetVisible( bool visible )
{
	CFieldPart::SetVisible( visible );
	
	[mView setHidden: !visible];
}


void	CFieldPartMac::SetEnabled( bool n )
{
	CFieldPart::SetEnabled( n );

	if( mTextView )
	{
		[mView setLineColor: n ? [NSColor colorWithCalibratedRed: mLineColorRed / 65535.0 green: mLineColorGreen / 65535.0 blue: mLineColorBlue / 65535.0 alpha: mLineColorAlpha / 65535.0] : [NSColor disabledControlTextColor]];
		[mTextView setEditable: n && !GetLockText()];
	}
	else
		[mTableView setEnabled: n];
}


void	CFieldPartMac::SetAutoSelect( bool n )
{
	NSView*	oldSuper = mView.superview;
	DestroyView();
	CFieldPart::SetAutoSelect( n );
	if( oldSuper )
		CreateViewIn( oldSuper );
}


void	CFieldPartMac::SetLockText( bool n )
{
	CFieldPart::SetLockText( n );

	if( mTextView )
	{
		[mTextView setEditable: !n && GetEnabled()];
		[mTextView setSelectable: !n];
	}
	else
		[mTableView.tableColumns[0] setEditable: !n];
}


void	CFieldPartMac::SetFillColor( int r, int g, int b, int a )
{
	CFieldPart::SetFillColor( r, g, b, a );

	[mView setBackgroundColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0]];
}


void	CFieldPartMac::SetLineColor( int r, int g, int b, int a )
{
	CFieldPart::SetLineColor( r, g, b, a );

	[mView setLineColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0]];
}


void	CFieldPartMac::SetShadowColor( int r, int g, int b, int a )
{
	CFieldPart::SetShadowColor( r, g, b, a );
	
	[mView.layer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CFieldPartMac::SetShadowOffset( double w, double h )
{
	CFieldPart::SetShadowOffset( w, h );
	
	[mView.layer setShadowOffset: NSMakeSize(w,h)];
}


void	CFieldPartMac::SetShadowBlurRadius( double r )
{
	CFieldPart::SetShadowBlurRadius( r );
	
	[mView.layer setShadowRadius: r];
}


void	CFieldPartMac::SetLineWidth( int w )
{
	CFieldPart::SetLineWidth( w );
	
	[mView setLineWidth: w];
}


void	CFieldPartMac::SetBevelWidth( int bevel )
{
	CFieldPart::SetBevelWidth( bevel );
}


void	CFieldPartMac::SetBevelAngle( int a )
{
	CFieldPart::SetBevelAngle( a );
}


/*static*/ size_t	CFieldPartMac::UTF8OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr )
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


/*static*/ size_t	CFieldPartMac::UTF32OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr )
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


/*static*/ NSInteger	CFieldPartMac::UTF16OffsetFromUTF32OffsetInCocoaString( size_t inUTF32Offs, NSString* cocoaStr )
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


void	CFieldPartMac::SetSelectedRange( LEOChunkType inType, size_t inStartOffs, size_t inEndOffs )
{
	if( mTableView )
	{
		if( inEndOffs < inStartOffs )
			[mTableView deselectAll: nil];
		else
		{
			NSRange		lineRange = { inStartOffs -1, inEndOffs -inStartOffs +1 };
			[mTableView selectRowIndexes: [NSIndexSet indexSetWithIndexesInRange: lineRange] byExtendingSelection: NO];
		}
	}
	else
	{
		if( inEndOffs < inStartOffs )
		{
			NSInteger selStart = 0;
			if( mTextView.textStorage.length > 0 )
				selStart = mTextView.textStorage.length -1;
			[mTextView setSelectedRange: NSMakeRange(selStart,0)];
		}
		else
		{
			NSRange	cocoaRange;
			cocoaRange.location = UTF16OffsetFromUTF32OffsetInCocoaString( inStartOffs -1, [[mTextView textStorage] string] );
			cocoaRange.length = UTF16OffsetFromUTF32OffsetInCocoaString( inEndOffs -1, [[mTextView textStorage] string] ) +1 -cocoaRange.location;
			[mTextView setSelectedRange: cocoaRange];
		}
	}
}


void	CFieldPartMac::GetSelectedRange( LEOChunkType* outType, size_t* outStartOffs, size_t* outEndOffs )
{
	if( mTableView )
	{
		NSInteger selLine = [mTableView selectedRow];
		*outStartOffs = selLine +1;
		*outEndOffs = selLine +1;
		*outType = kLEOChunkTypeLine;
	}
	else
	{
		NSRange	selRange = [mTextView selectedRange];
		*outStartOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location, [[mTextView textStorage] string] ) +1;
		*outEndOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location +selRange.length, [[mTextView textStorage] string] );
		*outType = kLEOChunkTypeCharacter;
	}
}


void	CFieldPartMac::LoadChangedTextStylesIntoView()
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( mAutoSelect )
	{
		ListChunkCallbackContext	ctx = { .lines = [[NSMutableArray alloc] init], .contents = contents, .defaultAttrs = GetCocoaAttributesForPart() };
		if( contents )
			LEODoForEachChunk( contents->GetText().c_str(), contents->GetText().length(), kLEOChunkTypeLine, ListChunkCallback, 0, &ctx );
		[mMacDelegate setLines: ctx.lines];
		[ctx.lines release];
		[mTableView reloadData];
	}
	else if( contents )
	{
		CAttributedString&		cppstr = contents->GetAttributedText();
		NSAttributedString*		attrStr = GetCocoaAttributedString( cppstr, GetCocoaAttributesForPart() );
		if( cppstr.GetString().find("{\\rtf1\\ansi\\") == 0 )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
		{
			NSDictionary*	docAttrs = nil;
			attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: cppstr.GetString().c_str() length: cppstr.GetLength()] documentAttributes: &docAttrs];
		}
		[mTextView.textStorage setAttributedString: attrStr];
	}
	else
		[mTextView setString: @""];
}


void	CFieldPartMac::LoadChangedTextFromView()
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
	{
		CAttributedString&		cppstr = contents->GetAttributedText();
		NSAttributedString*		attrStr = [mTextView textStorage];
		SetAttributedStringWithCocoa( cppstr, attrStr );
	}
	
	mViewTextNeedsSync = false;
}


NSDictionary*	CFieldPartMac::GetCocoaAttributesForPart()
{
	NSMutableDictionary	*	styles = [NSMutableDictionary dictionary];
	NSFont	*				theFont = nil;
	CGFloat					fontSize = mTextSize;
	if( fontSize < 0 )
		fontSize = [NSFont systemFontSize];
	if( mFont.length() > 0 )
		theFont = [NSFont fontWithName: [NSString stringWithUTF8String: mFont.c_str()] size: fontSize];
	else
		theFont = [NSFont systemFontOfSize: fontSize];
	
	if( mTextStyle & EPartTextStyleBold )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSBoldFontMask];
		if( newFont )
			theFont = newFont;
	}
	if( mTextStyle & EPartTextStyleItalic )
	{
		NSFont*	newFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
		if( newFont )
			theFont = newFont;
	}
	if( mTextStyle & EPartTextStyleUnderline )
	{
		[styles setObject: @(NSUnderlineStyleSingle) forKey: NSUnderlineStyleAttributeName];
	}
	if( mTextStyle & EPartTextStyleOutline )
	{
		[styles setObject: @-3.0 forKey: NSStrokeWidthAttributeName];
	}
	if( mTextStyle & EPartTextStyleShadow )
	{
		NSShadow*	textShadow = [[[NSShadow alloc] init] autorelease];
		[textShadow setShadowColor: NSColor.blackColor];
		[textShadow setShadowOffset: NSMakeSize(1,1)];
		[styles setObject: textShadow forKey: NSShadowAttributeName];
	}
	if( mTextStyle & EPartTextStyleCondensed )
		[styles setObject: @(-3.0) forKey: NSKernAttributeName];
	if( mTextStyle & EPartTextStyleExtended )
		[styles setObject: @(3.0) forKey: NSKernAttributeName];
	if( mTextStyle & EPartTextStyleGroup )
		[styles setObject: [NSURL URLWithString: @"http://#"] forKey: NSLinkAttributeName];

	[styles setObject: theFont forKey: NSFontAttributeName];
	
	return styles;
}


NSAttributedString	*	CFieldPartMac::GetCocoaAttributedString( const CAttributedString& attrStr, NSDictionary * defaultAttrs, size_t startOffs, size_t endOffs )
{
//	attrStr.Dump();
	size_t	len = ((endOffs != SIZE_T_MAX) ? endOffs : attrStr.GetLength()) -startOffs;
	NSMutableAttributedString	*	newAttrStr = [[[NSMutableAttributedString alloc] initWithString: [[[NSString alloc] initWithBytes: attrStr.GetString().c_str() +startOffs length: len encoding: NSUTF8StringEncoding] autorelease] attributes: defaultAttrs] autorelease];
	size_t	utf16StartOffs = attrStr.UTF16OffsetFromUTF8Offset(startOffs);
	attrStr.ForEachRangeDo([newAttrStr,&attrStr,utf16StartOffs,defaultAttrs,endOffs,startOffs](size_t currOffs, size_t currLen, CAttributeRange *currRange, const std::string &txt)
	{
//		std::cout << "\"" << txt << "\"" << std::endl;
		if( currRange )
		{
//			std::cout << currRange->mAttributes.size() << " attributes." << std::endl;
//			std::cout << currRange->mStart << " > " << endOffs << " || " << currRange->mEnd << " < " << startOffs << std::endl;
			if( currRange->mStart > endOffs || currRange->mEnd < startOffs )
			{
//				std::cout << "Skipping." << std::endl;
				return;
			}
			NSRange	currCocoaRange = { currRange->mStart, currRange->mEnd -currRange->mStart };
//			std::cout << "currCocoaRange = {" << currRange->mStart << "," << (currRange->mEnd -currRange->mStart) << "}" << std::endl;
			if( currCocoaRange.location < startOffs )
			{
				currCocoaRange.length -= startOffs -currCocoaRange.location;
				currCocoaRange.location = startOffs;
//				std::cout << "\tSTARTS BEFORE: currCocoaRange = {" << currRange->mStart << "," << (currRange->mEnd -currRange->mStart) << "}" << std::endl;
			}
			if( (currCocoaRange.location +currCocoaRange.length) > endOffs )
			{
				currCocoaRange.length -= (currCocoaRange.location +currCocoaRange.length) -endOffs;
//				std::cout << "\tENDS AFTER: currCocoaRange = {" << currRange->mStart << "," << (currRange->mEnd -currRange->mStart) << "}" << std::endl;
			}
			
			// Convert UTF8 to UTF16 range:
			currCocoaRange.length = attrStr.UTF16OffsetFromUTF8Offset(currCocoaRange.location +currCocoaRange.length);
			currCocoaRange.location = attrStr.UTF16OffsetFromUTF8Offset(currCocoaRange.location);
			currCocoaRange.length -= currCocoaRange.location;
			currCocoaRange.location -= utf16StartOffs;
//			std::cout << "\tcurrCocoaRange = {" << currRange->mStart << "," << (currRange->mEnd -currRange->mStart) << "}" << std::endl;
			
			NSFont	*	newFont = nil;
			for( auto currStyle : currRange->mAttributes )
			{
//				std::cout << "Style: " << currStyle.first << std::endl;
				if( currStyle.first.compare("text-decoration") == 0 && currStyle.second.compare("underline") == 0 )
				{
//					std::cout << "\tAdding underline." << std::endl;
					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("text-style") == 0 && currStyle.second.compare("italic") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toHaveTrait: NSItalicFontMask];
					if( changedFont && [[NSFontManager sharedFontManager] traitsOfFont: changedFont] & NSItalicFontMask )
					{
						newFont = changedFont;
//						std::cout << "\tAdding italic." << std::endl;
					}
					else
					{
						[newAttrStr addAttribute: NSObliquenessAttributeName value: @(0.5) range: currCocoaRange];
//						std::cout << "\tAdding oblique." << std::endl;
					}
				}
				else if( currStyle.first.compare("font-weight") == 0 && currStyle.second.compare("bold") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toHaveTrait: NSBoldFontMask];
					if( changedFont )
					{
//						std::cout << "\tAdding bold." << std::endl;
						newFont = changedFont;
					}
					else
						;//std::cout << "\tAdding bold failed." << std::endl;
				}
				else if( currStyle.first.compare("font-family") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toFamily: [NSString stringWithUTF8String: currStyle.second.c_str()]];
					if( changedFont )
					{
						newFont = changedFont;
//						std::cout << "\tChanged font family." << std::endl;
					}
					else
						;//std::cout << "\tFailed to change font family." << std::endl;
				}
				else if( currStyle.first.compare("font-size") == 0 )
				{
					char*		endPtr = NULL;
					LEOInteger	fontSize = strtoll( currStyle.second.c_str(), &endPtr, 10 );
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toSize: fontSize];
					if( changedFont )
					{
						newFont = changedFont;
//						std::cout << "\tChanged font size." << std::endl;
					}
					else
						;//std::cout << "\tFailed to change font size." << std::endl;
				}
				else if( currStyle.first.compare("$link") == 0 )
				{
					[newAttrStr addAttribute: NSLinkAttributeName value: [NSURL URLWithString: [NSString stringWithUTF8String: currStyle.second.c_str()]] range: currCocoaRange];
//					std::cout << "\tAdded link." << std::endl;
				}
				// +++ Add outline/shadow/condense/extend
			}
			if( newFont )
			{
				[newAttrStr addAttribute: NSFontAttributeName value: newFont range: currCocoaRange];
//				std::cout << "\tFont changed." << std::endl;
			}
			else
				;//std::cout << "\tDidn't have to change font." << std::endl;
		}
	});
//	std::cout << std::endl;
	return newAttrStr;
}


void	CFieldPartMac::SetAttributedStringWithCocoa( CAttributedString& stringToSet, NSAttributedString* cocoaAttrStr )
{
//	stringToSet.Dump();
	
	stringToSet.SetString( cocoaAttrStr.string.UTF8String );
	
	[cocoaAttrStr enumerateAttributesInRange: NSMakeRange(0,cocoaAttrStr.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
	{
		assert( range.location <= (range.location +range.length) );
		for( NSString* currAttr in attrs )
		{
			id attrValue = attrs[currAttr];
			if( [currAttr isEqualToString: NSFontAttributeName] )
			{
				stringToSet.AddAttributeValueForRange( "font-family", [attrValue familyName].UTF8String, range.location, range.location +range.length );
				
				char		str[512] = {0};
				snprintf(str, sizeof(str)-1, "%lld", (LEOInteger) [attrValue pointSize]);
				stringToSet.AddAttributeValueForRange( "font-size", str, range.location, range.location +range.length );
				
				NSFontTraitMask	traits = [[NSFontManager sharedFontManager] traitsOfFont: attrValue];
				if( traits & NSBoldFontMask )
				{
					stringToSet.AddAttributeValueForRange( "font-weight", "bold", range.location, range.location +range.length );
				}
				if( traits & NSItalicFontMask )
				{
					stringToSet.AddAttributeValueForRange( "text-style", "italic", range.location, range.location +range.length );
				}
			//	stringToSet.Dump();
			}
			else if( [currAttr isEqualToString: NSObliquenessAttributeName] && [attrValue integerValue] != 0 )
			{
				stringToSet.AddAttributeValueForRange( "text-style", "italic", range.location, range.location +range.length );
			//	stringToSet.Dump();
			}
			else if( [currAttr isEqualToString: NSUnderlineStyleAttributeName] && [attrValue integerValue] == NSUnderlineStyleSingle )
			{
				stringToSet.AddAttributeValueForRange( "text-decoration", "underline", range.location, range.location +range.length );
			//	stringToSet.Dump();
			}
			else if( [currAttr isEqualToString: NSLinkAttributeName] )
			{
				stringToSet.AddAttributeValueForRange( "$link", [[attrValue absoluteString] UTF8String], range.location, range.location +range.length );
			//	stringToSet.Dump();
			}
		}
	}];

//	stringToSet.Dump();
}


void	CFieldPartMac::SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	CFieldPart::SetRect( left, top, right, bottom );
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	GetStack()->RectChangedOfPart( this );
}


NSView*	CFieldPartMac::GetView()
{
	return mView;
}

