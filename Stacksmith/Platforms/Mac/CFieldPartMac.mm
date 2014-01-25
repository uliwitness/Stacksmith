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


using namespace Carlson;


@interface WILDFieldDelegate : NSObject <NSTextFieldDelegate,NSTableViewDelegate, NSTableViewDataSource>

@property (assign,nonatomic) CFieldPartMac*	owningField;
@property (retain,nonatomic) NSArray*		lines;

@end

@implementation WILDFieldDelegate

-(void)	dealloc
{
	self.lines = nil;
	
	[super dealloc];
}

-(BOOL)	control: (NSControl *)control textShouldBeginEditing: (NSText *)fieldEditor
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textStorageDidProcessEditing:) name: NSTextStorageDidProcessEditingNotification object: ((NSTextView*) fieldEditor).textStorage];
//	NSLog( @"Editing started." );
	return YES;
}


-(BOOL)	control: (NSControl *)control textShouldEndEditing: (NSText *)fieldEditor
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSTextStorageDidProcessEditingNotification object: ((NSTextView*) fieldEditor).textStorage];
//	NSLog( @"Editing stopped." );
	
	return YES;
}


-(void)	controlTextDidChange: (NSNotification *)obj
{
	self.owningField->SetViewTextNeedsSync( true );
//	NSLog( @"Edited text." );
}


-(void)	textStorageDidProcessEditing: (NSNotification *)obj
{
	self.owningField->SetViewTextNeedsSync( true );
//	NSLog( @"Edited styles or so." );
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


@end;


static bool	ListChunkCallback( const char* currStr, size_t currLen, size_t currStart, size_t currEnd, void* userData )
{
	NSMutableArray	*	lines = (NSMutableArray*)userData;
	NSString	*		itemTitle = [[NSString alloc] initWithBytes: currStr length: currLen encoding:NSUTF8StringEncoding];
	[lines addObject: itemTitle];
		
	return true;
}


CFieldPartMac::CFieldPartMac( CLayer *inOwner )
	: CFieldPart( inOwner ), mView(nil), mMacDelegate(nil), mTableView(nil)
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
	mMacDelegate = [[WILDFieldDelegate alloc] init];
	mMacDelegate.owningField = this;
	if( mAutoSelect )
	{
		mTableView = [WILDViewFactory tableViewInContainer];
		mTableView.dataSource = mMacDelegate;
		mTableView.delegate = mMacDelegate;
		mView = (NSTextField*)[[mTableView enclosingScrollView] retain];
	}
	else
	{
		mView = [[WILDViewFactory textField] retain];
		mView.delegate = mMacDelegate;
	}
	if( mAutoSelect )
	{
		LoadChangedTextStylesIntoView();
	}
	else
	{
		CPartContents*	contents = GetContentsOnCurrentCard();
		if( contents )
		{
			CAttributedString&		cppstr = contents->GetAttributedText();
			NSAttributedString*		attrStr = GetCocoaAttributedString( &cppstr, GetCocoaAttributesForPart() );
			bool					oldRTF = cppstr.GetString().find("{\\rtf1\\ansi\\") == 0;
			if( oldRTF )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
			{
				NSDictionary*	docAttrs = nil;
				attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: cppstr.GetString().c_str() length: cppstr.GetString().length()] documentAttributes: &docAttrs];
			}
			[mView setAttributedStringValue: attrStr];
			if( oldRTF )
				SetAttributedStringWithCocoa( cppstr, attrStr );	// Save the parsed RTF back as something the cross-platform code understands.
		}
		else
			[mView setStringValue: @""];
	}
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


void	CFieldPartMac::SetFieldStyle( TFieldStyle inFieldStyle )
{
	NSView*	oldSuper = mView.superview;
	DestroyView();
	CFieldPart::SetFieldStyle(inFieldStyle);
	if( oldSuper )
		CreateViewIn( oldSuper );
}


void	CFieldPartMac::LoadChangedTextStylesIntoView()
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( mAutoSelect )
	{
		NSMutableArray	*	theLines = [[NSMutableArray alloc] init];
		std::string		contentsStr;
		GetTextContents(contentsStr);
		LEODoForEachChunk( contentsStr.c_str(), contentsStr.length(), kLEOChunkTypeLine, ListChunkCallback, 0, theLines );
		[mMacDelegate setLines: theLines];
		[mTableView reloadData];
	}
	else if( contents )
	{
		CAttributedString&		cppstr = contents->GetAttributedText();
		NSAttributedString*		attrStr = GetCocoaAttributedString( &cppstr, GetCocoaAttributesForPart() );
		if( cppstr.GetString().find("{\\rtf1\\ansi\\") == 0 )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
		{
			NSDictionary*	docAttrs = nil;
			attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: cppstr.GetString().c_str() length: cppstr.GetString().length()] documentAttributes: &docAttrs];
		}
		[mView setAttributedStringValue: attrStr];
	}
	else
		[mView setStringValue: @""];
}


void	CFieldPartMac::LoadChangedTextFromView()
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
	{
		CAttributedString&		cppstr = contents->GetAttributedText();
		NSAttributedString*		attrStr = [mView attributedStringValue];
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


NSAttributedString	*	CFieldPartMac::GetCocoaAttributedString( CAttributedString * attrStr, NSDictionary * defaultAttrs )
{
//	attrStr->Dump();
	NSMutableAttributedString	*	newAttrStr = [[[NSMutableAttributedString alloc] initWithString: [NSString stringWithUTF8String: attrStr->GetString().c_str()] attributes: defaultAttrs] autorelease];
	attrStr->ForEachRangeDo([newAttrStr,defaultAttrs](CAttributeRange *currRange, const std::string &txt)
	{
		if( currRange )
		{
			NSRange	currCocoaRange = { currRange->mStart, currRange->mEnd -currRange->mStart };
			
			// +++ Convert UTF8 to UTF16 range!
			
			NSFont	*	newFont = nil;
			for( auto currStyle : currRange->mAttributes )
			{
				if( currStyle.first.compare("text-decoration") == 0 && currStyle.second.compare("underline") == 0 )
				{
					[newAttrStr addAttribute: NSUnderlineStyleAttributeName value: @(NSUnderlineStyleSingle) range: currCocoaRange];
				}
				else if( currStyle.first.compare("text-style") == 0 && currStyle.second.compare("italic") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toHaveTrait: NSItalicFontMask];
					if( changedFont && [[NSFontManager sharedFontManager] traitsOfFont: changedFont] & NSItalicFontMask )
						newFont = changedFont;
					else
					{
						[newAttrStr addAttribute: NSObliquenessAttributeName value: @(0.5) range: currCocoaRange];
					}
				}
				else if( currStyle.first.compare("font-weight") == 0 && currStyle.second.compare("bold") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toHaveTrait: NSBoldFontMask];
					if( changedFont )
						newFont = changedFont;
				}
				else if( currStyle.first.compare("font-family") == 0 )
				{
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toFamily: [NSString stringWithUTF8String: currStyle.second.c_str()]];
					if( changedFont )
						newFont = changedFont;
				}
				else if( currStyle.first.compare("font-size") == 0 )
				{
					char*		endPtr = NULL;
					LEOInteger	fontSize = strtoll( currStyle.second.c_str(), &endPtr, 10 );
					NSFont*	changedFont = [[NSFontManager sharedFontManager] convertFont: (newFont ? newFont : defaultAttrs[NSFontAttributeName]) toSize: fontSize];
					if( changedFont )
						newFont = changedFont;
				}
				else if( currStyle.first.compare("$link") == 0 )
				{
					[newAttrStr addAttribute: NSLinkAttributeName value: [NSURL URLWithString: [NSString stringWithUTF8String: currStyle.second.c_str()]] range: currCocoaRange];
				}
				// +++ Add outline/shadow/condense/extend
			}
			if( newFont )
				[newAttrStr addAttribute: NSFontAttributeName value: newFont range: currCocoaRange];
		}
	});
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