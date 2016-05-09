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
#import "WILDTextView.h"
#import "WILDTableView.h"
#include "CAlert.h"
#include "CStack.h"
#include "UTF8UTF32Utilities.h"
#include "CDocument.h"
#import "UKHelperMacros.h"
#import "UKPushbackMessenger.h"
#import "WILDSearchField.h"
#import "WILDComboBox.h"


using namespace Carlson;


// Combo boxes are fixed in their heights. As parts aren't, just show them at the
//	system-defined height to make things look right:
#define SYSTEM_DEFINED_COMBOBOX_HEIGHT		26



@interface WILDFieldDelegate : NSObject <NSTextViewDelegate,NSTableViewDelegate, NSTableViewDataSource,NSTextFieldDelegate,NSComboBoxDataSource,NSSearchFieldDelegate>

@property (assign,nonatomic) CFieldPartMac*			owningField;
@property (retain,nonatomic) NSMutableArray*		lines;
@property (assign,nonatomic) BOOL					dontSendSelectionChange;
@property (assign,nonatomic) BOOL					multipleColumns;
@property (retain,nonatomic) NSMutableDictionary*	images;
@property (assign,nonatomic) NSTableView*			table;
@property (assign,nonatomic) WILDSearchField*		searchField;

@end

@implementation WILDFieldDelegate

@synthesize images;
@synthesize lines;

-(void)	dealloc
{
	self.images = nil;
	self.lines = nil;
	
	[super dealloc];
}


-(NSMutableDictionary*)	images
{
	if( !images )
	{
		images = [[NSMutableDictionary alloc] init];
	}
	return images;
}


-(void)	controlTextDidChange:(NSNotification *)notif	// Search field text changed.
{
	if( self.owningField->GetStyle() == EFieldStylePopUp )
	{
		lines[0] = [notif.object attributedStringValue];
	}
	self.owningField->SetViewTextNeedsSync( true );
	CPartContents*	contents = self.owningField->GetContentsOnCurrentCard();
	if( contents ) contents->IncrementChangeCount();
//	NSLog( @"Edited SEARCH field text." );

	CAutoreleasePool	pool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "textChange" );
}


-(void)	textDidChange: (NSNotification *)notif	// Regular multi-line field text changed.
{
	self.owningField->SetViewTextNeedsSync( true );
	CPartContents*	contents = self.owningField->GetContentsOnCurrentCard();
	if( contents ) contents->IncrementChangeCount();
//	NSLog( @"Edited regular field text." );

	CAutoreleasePool	pool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "textChange" );
}


-(void)	returnInFieldOrFinishedEditing: (id)sender
{
	CAutoreleasePool	pool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "closeField" );
}


-(void)	textViewDidChangeTypingAttributes: (NSNotification *)notification
{
	if( !self.dontSendSelectionChange )
	{
		self.owningField->SetViewTextNeedsSync( true );
		CPartContents*	contents = self.owningField->GetContentsOnCurrentCard();
		if( contents ) contents->IncrementChangeCount();
	//	NSLog( @"Edited styles or so." );
	}
}


-(BOOL)	textView: (NSTextView *)textView clickedOnLink: (id)link atIndex: (NSUInteger)charIndex
{
	CAutoreleasePool		pool;
	NSURL*	theLink = [textView.textStorage attribute: NSLinkAttributeName atIndex: charIndex effectiveRange:NULL];
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUpInLink %s", [[theLink absoluteString] UTF8String] );
	
	return YES;
}


-(void)	textViewDidChangeSelection: (NSNotification *)notification
{
	if( !self.dontSendSelectionChange )
	{
		CAutoreleasePool		pool;
		self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
	}
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView *)tableView
{
	return [self.lines count];
}


-(void)	setImage: (NSImage*)inImage forRow: (NSInteger)inRow column: (NSInteger)inColumn
{
	NSString* theKey = [NSString stringWithFormat: @"%ld-%ld", (long)inRow, (long)inColumn];
	[self.images setObject: inImage forKey: theKey];
	[self.table performSelector: @selector(reloadData) withObject: nil afterDelay: 0.0];	// In case we get called directly from the -tableView:objectValueForTableColumn:row: callback, which happens for local files.
}


-(NSImage*)	imageForRow: (NSInteger)inRow column: (NSInteger)inColumn
{
	NSString* theKey = [NSString stringWithFormat: @"%ld-%ld", (long)inRow, (long)inColumn];
	return [self.images objectForKey: theKey];
}


-(id)	tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( self.multipleColumns )
	{
		NSArray*	cols = [self.lines objectAtIndex: row];
		NSInteger	colIdx = [tableView.tableColumns indexOfObject: tableColumn];
		id			currCellContent = [cols objectAtIndex: colIdx];
		TColumnType	theColumnType = self.owningField->GetColumnInfo(colIdx).mType;
		if( theColumnType == EColumnTypeIcon )
		{
			CFieldPartMac*	theField = self.owningField;
			WILDNSImagePtr	theImage = [self imageForRow: row column: colIdx];
			if( !theImage )
			{
				//[self retain];
				NSInteger	iconID = [[currCellContent string] integerValue];
				if( iconID == 0 )
				{
					iconID = theField->GetDocument()->GetMediaCache().GetMediaIDByNameOfType( [[currCellContent string] UTF8String], EMediaTypeIcon );
					theField->GetDocument()->GetMediaCache().GetMediaImageByIDOfType( iconID, EMediaTypeIcon, [self,row,colIdx](WILDNSImagePtr inImage, int xHotSpot, int yHotSpot)
					{
						if( inImage )
							[self setImage: inImage forRow: row column: colIdx];
						//[self release];
					});
				}
				else
				{
					theField->GetDocument()->GetMediaCache().GetMediaImageByIDOfType( iconID, EMediaTypeIcon, [self,row,colIdx](WILDNSImagePtr inImage, int xHotSpot, int yHotSpot)
					{
						if( inImage )
							[self setImage: inImage forRow: row column: colIdx];
						//[self release];
					});
				}
			}
			return theImage;
		}
		else if( theColumnType == EColumnTypeCheckbox )
		{
			return (([[currCellContent string] caseInsensitiveCompare: @"true"] == 0) ? [NSNumber numberWithBool: YES] : [NSNumber numberWithBool: NO]);
		}
		return currCellContent;
	}
	else
		return [self.lines objectAtIndex: row];
}


-(void)	tableView: (NSTableView *)tableView setObjectValue: (id)theValue forTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( self.multipleColumns )
	{
		NSMutableArray*		cols = [self.lines objectAtIndex: row];
		NSInteger			colIdx = [tableView.tableColumns indexOfObject: tableColumn];
		TColumnType			theColumnType = self.owningField->GetColumnInfo(colIdx).mType;
		if( theColumnType == EColumnTypeCheckbox )
		{
			if( [theValue boolValue] )
			{
				theValue = [[[NSAttributedString alloc] initWithString: @"true" attributes: @{}] autorelease];
			}
			else
			{
				theValue = [[[NSAttributedString alloc] initWithString: @"false" attributes: @{}] autorelease];
			}
		}
		else if( theColumnType == EColumnTypeText )
		{
			if( [theValue isKindOfClass: [NSString class]] )	// Permit unstyled text.
				theValue = [[[NSAttributedString alloc] initWithString: theValue attributes: @{}] autorelease];
			else
				theValue = theValue;
		}
		[cols replaceObjectAtIndex: colIdx withObject: theValue];
	}
	else
	{
		if( ![theValue isKindOfClass: [NSAttributedString class]] )
		{
			theValue = [[[NSAttributedString alloc] initWithString: theValue attributes: self.owningField->GetCocoaAttributesForPart()] autorelease];
		}
		[self.lines replaceObjectAtIndex: row withObject: theValue];
	}
	
	self.owningField->SetViewTextNeedsSync( true );
	CPartContents*	contents = self.owningField->GetContentsOnCurrentCard();
	if( contents ) contents->IncrementChangeCount();
}


-(void)	tableViewSelectionDidChange:(NSNotification *)notification
{
	if( !self.dontSendSelectionChange )
	{
		self.owningField->ClearSelectedLines();
		NSIndexSet	*	selRows = [[notification object] selectedRowIndexes];
		NSInteger idx = [selRows firstIndex];
		while( idx != NSNotFound )
		{
			self.owningField->AddSelectedLine( idx +1 );
			
			idx = [selRows indexGreaterThanIndex: idx];
		}
		
		self.owningField->IncrementChangeCount();
		
		CAutoreleasePool	cppPool;
		self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
	}
}

-(BOOL)	tableView: (NSTableView *)tableView shouldEditTableColumn: (NSTableColumn *)tableColumn row: (NSInteger)row
{
	if( self.multipleColumns )
	{
		NSInteger			colIdx = [tableView.tableColumns indexOfObject: tableColumn];
		if( !self.owningField->GetColumnInfo(colIdx).mEditable )
			return NO;
	}
	return !self.owningField->GetLockText() || self.owningField->GetStack()->GetTool() == EEditTextTool;
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
	if( !self.owningField->GetLockText() || self.owningField->GetStack()->GetTool() == EEditTextTool )
	{
		NSInteger	currRow = [sender clickedRow];
		NSInteger	currColumn = [sender clickedColumn];
		[sender editColumn: currColumn row: currRow withEvent: nil select: YES];
	}
}


-(void)	setLines: (NSMutableArray*)inLines
{
	ASSIGN(lines,inLines);
	DESTROY(images);
}

-(NSInteger)	numberOfItemsInComboBox: (NSComboBox *)aComboBox;
{
	return lines.count -1;		// Skip first line, it's already displayed in the combo box.
}

-(id)	comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex: (NSInteger)index
{
	return lines[ index +1 ];	// Skip first line, it's already displayed in the combo box.
}

- (void)comboBoxSelectionDidChange: (NSNotification *)notification
{
	self.lines[0] = self.lines[((WILDComboBox*)notification.object).indexOfSelectedItem +1];
	
	self.owningField->SetViewTextNeedsSync( true );
	CPartContents*	contents = self.owningField->GetContentsOnCurrentCard();
	if( contents ) contents->IncrementChangeCount();

	CAutoreleasePool	cppPool;
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "mouseUp" );
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "selectionChange" );
	self.owningField->SendMessage( NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, "textChange" );
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
	: CFieldPart( inOwner ), mView(nil), mMacDelegate(nil), mTableView(nil), mTextView(nil), mSearchField(nil)
{
	
}


void	CFieldPartMac::DestroyView()
{
	if( mViewTextNeedsSync )
		LoadChangedTextFromView();
	
	if( mSearchField )
	{
		mSearchField.owningField = NULL;
	}
	if( mTextView )
		mTextView.owningPart = NULL;
	if( mTableView )
		mTableView.owningPart = NULL;
	if( mView )
		mView.owningPart = NULL;
	[mView.animator removeFromSuperview];
	DESTROY(mView);
	[mSearchField.animator removeFromSuperview];
	DESTROY(mSearchField);
	mTableView = nil;
	mTextView = nil;
	DESTROY(mMacDelegate);
}


void	CFieldPartMac::CreateViewIn( NSView* inSuperView )
{
	if( (mView && mView.superview == inSuperView)
		|| (mSearchField && mSearchField.superview == inSuperView) )
	{
		[mSearchField.animator removeFromSuperview];
		[mView.animator removeFromSuperview];
		if( mView )
			[inSuperView.animator addSubview: mView];	// Make sure we show up in right layering order.
		if( mSearchField )
			[inSuperView.animator addSubview: mSearchField];	// Make sure we show up in right layering order.
		return;
	}
	mMacDelegate = [[WILDFieldDelegate alloc] init];
	mMacDelegate.owningField = this;
	if( mAutoSelect )
	{
		mTableView = [WILDViewFactory tableViewInContainer];
		mTableView.owningPart = this;
		mTableView.dataSource = mMacDelegate;
		mTableView.delegate = mMacDelegate;
		mMacDelegate.table = mTableView;
		[mTableView setTarget: mMacDelegate];
		[mTableView setAction: @selector(tableViewRowClicked:)];
		[mTableView setDoubleAction: @selector(tableViewRowDoubleClicked:)];
		if( mHasColumnHeaders )
			mTableView.headerView = [[[NSTableHeaderView alloc] initWithFrame: NSMakeRect(0, 0, 60, 17)] autorelease];
		mView = (WILDScrollView*) [[mTableView enclosingScrollView] retain];
		mView.owningPart = this;
		
		NSInteger	numCols = [mTableView numberOfColumns];
		while( numCols-- > 0 )
			[mTableView removeTableColumn: mTableView.tableColumns.lastObject];
		
		size_t		actualNumColumns = mColumns.size();
		size_t 		numColumnsToCreate = actualNumColumns;
		if( numColumnsToCreate < 1 )
			numColumnsToCreate = 1;
		for( size_t x = 0; x < numColumnsToCreate; x++ )
		{
			NSTableColumn	*	col = [[NSTableColumn alloc] initWithIdentifier: [NSString stringWithFormat: @"%zu", x +1]];
			if( actualNumColumns > x )
			{
				const CColumnInfo&	currColumn = mColumns[x];
				[col.headerCell setTitle: [NSString stringWithUTF8String: currColumn.mName.c_str()]];
				col.width = currColumn.mWidth;
				switch( currColumn.mType )
				{
					case EColumnTypeCheckbox:
					{
						NSButtonCell*	btnCell = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
						[btnCell setButtonType: NSSwitchButton];
						[col setDataCell: btnCell];
						break;
					}
					case EColumnTypeIcon:
					{
						NSImageCell*	imgCell = [[[NSImageCell alloc] initImageCell: [NSImage imageNamed: @"NSApplicationIcon"]] autorelease];
						[col setDataCell: imgCell];
						break;
					}
					case EColumnTypeText:
					case EColumnType_Last:	// When opening new stack with old app, just treat it as text.
						NSTextFieldCell*	txtCell = [[[NSTextFieldCell alloc] initTextCell: @""] autorelease];
						txtCell.editable = YES;
						txtCell.allowsEditingTextAttributes = YES;
						[col setDataCell: txtCell];
						break;
				}
			}
			[mTableView addTableColumn: col];
			[col release];
		}
	}
	else if( mFieldStyle == EFieldStyleSearch )
	{
		mSearchField = [[WILDSearchField alloc] initWithFrame: ConvertToViewRect(GetLeft(), GetTop(), GetRight(), GetBottom())];
		[mSearchField beginWatchingForSelectionChanges];
		mSearchField.delegate = mMacDelegate;
		mSearchField.owningField = this;
		mMacDelegate.searchField = mSearchField;
		if( mAutoTab )
		{
			[mSearchField setTarget: mMacDelegate];
			[mSearchField setAction: @selector(returnInFieldOrFinishedEditing:)];
		}
	}
	else if( mFieldStyle == EFieldStylePopUp )
	{
		NSRect		box = ConvertToViewRect(GetLeft(), GetTop(), GetRight(), GetBottom());
		mSearchField = (WILDSearchField*)[[WILDComboBox alloc] initWithFrame: box];
		[mSearchField beginWatchingForSelectionChanges];
		mSearchField.delegate = mMacDelegate;
		mSearchField.owningField = this;
		mMacDelegate.searchField = mSearchField;
		((WILDComboBox*)mSearchField).usesDataSource = YES;
		((WILDComboBox*)mSearchField).dataSource = mMacDelegate;
		[(WILDComboBox*)mSearchField reloadData];
		if( mAutoTab )
		{
			[mSearchField setTarget: mMacDelegate];
			[mSearchField setAction: @selector(returnInFieldOrFinishedEditing:)];
		}
	}
	else
	{
		mTextView = [WILDViewFactory textViewInContainer];
		mTextView.owningPart = this;
		mTextView.delegate = mMacDelegate;
		mView = (WILDScrollView*) [[mTextView enclosingScrollView] retain];
		mView.owningPart = this;
		[mTextView setDrawsBackground: NO];
		[mTextView setBackgroundColor: [NSColor clearColor]];
		[mTextView setFieldEditor: mAutoTab == true];
	}
	if( mView )
	{
		[mView setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
		[mView setBackgroundColor: [NSColor colorWithCalibratedRed: (mFillColorRed / 65535.0) green: (mFillColorGreen / 65535.0) blue: (mFillColorBlue / 65535.0) alpha:(mFillColorAlpha / 65535.0)]];
		[mView setHasHorizontalScroller: mHasHorizontalScroller != false];
		[mView setHasVerticalScroller: mHasVerticalScroller != false || mFieldStyle == EFieldStyleScrolling];
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
	}
	else
	{
		[mSearchField setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
	}
	mMacDelegate.dontSendSelectionChange = YES;
	if( mAutoSelect )
	{
		LoadChangedTextStylesIntoView();
		[mTableView.tableColumns[0] setEditable: !GetLockText() || GetStack()->GetTool() == EEditTextTool];
				
		[mTableView deselectAll: nil];
		std::set<size_t>	selLines = mSelectedLines;
		for( size_t currLine : selLines )
		{
			[mTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: currLine -1] byExtendingSelection: YES];
		}
	}
	else if( mFieldStyle == EFieldStylePopUp )
	{
		LoadChangedTextStylesIntoView();
		[mSearchField setEditable: (!GetLockText() && GetEnabled()) || GetStack()->GetTool() == EEditTextTool];
		[mSearchField setSelectable: !GetLockText() || GetStack()->GetTool() == EEditTextTool];
	}
	else if( mSearchField )
	{
		CPartContents*			contents = GetContentsOnCurrentCard();
		if( contents )
		{
			CAttributedString&		cppstr = contents->GetAttributedText();
			NSAttributedString*		attrStr = GetCocoaAttributedString( cppstr, GetCocoaAttributesForPart() );
			[mSearchField setAttributedStringValue: attrStr];
		}
		[mSearchField setEditable: (!GetLockText() && GetEnabled()) || GetStack()->GetTool() == EEditTextTool];
		[mSearchField setSelectable: !GetLockText() || GetStack()->GetTool() == EEditTextTool];
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
			{
				SetAttributedStringWithCocoa( cppstr, attrStr );	// Save the parsed RTF back as something the cross-platform code understands.
			}
		}
		else
			[mTextView setString: @""];
		[mTextView setEditable: (!GetLockText() && GetEnabled()) || GetStack()->GetTool() == EEditTextTool];
		[mTextView setSelectable: !GetLockText() || GetStack()->GetTool() == EEditTextTool];
	}
	mMacDelegate.dontSendSelectionChange = NO;
	if( mView )
	{
		[mView setFrame: NSMakeRect(GetLeft(), GetTop(), GetRight() -GetLeft(), GetBottom() -GetTop())];
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
		[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
		[mView.layer setShadowRadius: mShadowBlurRadius];
		[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
		[mView setToolTip: [NSString stringWithUTF8String: mToolTip.c_str()]];
		[inSuperView.animator addSubview: mView];

		[mView setDocumentCursor: [NSCursor arrowCursor]];
		
		GetDocument()->GetMediaCache().GetMediaImageByIDOfType( mCursorID, EMediaTypeCursor,
		[this]( WILDNSImagePtr inImage, int xHotSpot, int yHotSpot )
		{
			NSCursor *theCursor = (GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : [[[NSCursor alloc] initWithImage: inImage hotSpot: NSMakePoint(xHotSpot, yHotSpot)] autorelease];
			[mView setDocumentCursor: theCursor];
		} );
	}
	else
	{
		[mSearchField.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
		[mSearchField.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
		[mSearchField.layer setShadowRadius: mShadowBlurRadius];
		[mSearchField.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
		[mSearchField setToolTip: [NSString stringWithUTF8String: mToolTip.c_str()]];
		[inSuperView.animator addSubview: mSearchField];
	}
}


NSRect	CFieldPartMac::ConvertToViewRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	NSRect		box = NSMakeRect(left, top, right -left, bottom -top);
	if( mFieldStyle == EFieldStylePopUp )
	{
		box.origin.y += truncf((box.size.height - SYSTEM_DEFINED_COMBOBOX_HEIGHT) / 2);
		box.size.height = SYSTEM_DEFINED_COMBOBOX_HEIGHT;
	}
	
	return box;
}


void	CFieldPartMac::SetHasColumnHeaders( bool inCH )
{
	CFieldPart::SetHasColumnHeaders( inCH );
	if( mHasColumnHeaders )
	{
		mTableView.headerView = [[[NSTableHeaderView alloc] initWithFrame: NSMakeRect(0, 0, 60, 17)] autorelease];
		[mTableView tile];
	}
	else
		mTableView.headerView = nil;
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
	NSView*	oldSuper = (mView? mView : mSearchField).superview;
	DestroyView();
	CFieldPart::SetStyle(inFieldStyle);
	if( oldSuper )
		CreateViewIn( oldSuper );
}


void	CFieldPartMac::SetVisible( bool visible )
{
	CFieldPart::SetVisible( visible );
	
	[(mView? mView : mSearchField) setHidden: !visible];
}


void	CFieldPartMac::SetEnabled( bool n )
{
	CFieldPart::SetEnabled( n );

	if( mTextView )
	{
		[mView setLineColor: n ? [NSColor colorWithCalibratedRed: mLineColorRed / 65535.0 green: mLineColorGreen / 65535.0 blue: mLineColorBlue / 65535.0 alpha: mLineColorAlpha / 65535.0] : [NSColor disabledControlTextColor]];
		[mTextView setEditable: (n && !GetLockText()) || GetStack()->GetTool() == EEditTextTool];
	}
	else if( mSearchField )
	{
		[mSearchField setEnabled: n || GetStack()->GetTool() == EEditTextTool];
	}
	else
		[mTableView setEnabled: n || GetStack()->GetTool() == EEditTextTool];
}


void	CFieldPartMac::SetAutoSelect( bool n )
{
	NSView*	oldSuper = (mView? mView : mSearchField).superview;
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
	else if( mSearchField )
	{
		[mSearchField setEditable: !n && GetEnabled()];
		[mSearchField setSelectable: !n];
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
	
	[(mView? mView : mSearchField).layer setShadowOpacity: (a == 0) ? 0.0 : 1.0];
	if( a != 0 )
	{
		[(mView? mView : mSearchField).layer setShadowColor: [NSColor colorWithCalibratedRed: r / 65535.0 green: g / 65535.0 blue: b / 65535.0 alpha: a / 65535.0].CGColor];
	}
}


void	CFieldPartMac::SetShadowOffset( double w, double h )
{
	CFieldPart::SetShadowOffset( w, h );
	
	[(mView? mView : mSearchField).layer setShadowOffset: NSMakeSize(w,h)];
}


void	CFieldPartMac::SetShadowBlurRadius( double r )
{
	CFieldPart::SetShadowBlurRadius( r );
	
	[(mView? mView : mSearchField).layer setShadowRadius: r];
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


void	CFieldPartMac::SetAutoTab( bool inST )
{
	CFieldPart::SetAutoTab(inST);
	
	if( mTextView )
	{
		[mTextView setFieldEditor: mAutoTab];
	}
	else if( mSearchField )
	{
		[mSearchField setTarget: mAutoTab ? mMacDelegate : nil];
		[mSearchField setAction: mAutoTab ? @selector(returnInFieldOrFinishedEditing:) : NULL];
	}
}


void	CFieldPartMac::SetCursorID( ObjectID inID )
{
	CFieldPart::SetCursorID( inID );
	
	// +++ Implement cursor for search field.
	
	[mView setDocumentCursor: [NSCursor arrowCursor]];
	
	GetDocument()->GetMediaCache().GetMediaImageByIDOfType( inID, EMediaTypeCursor,
	[this]( WILDNSImagePtr inImage, int xHotSpot, int yHotSpot )
	{
		NSCursor *theCursor = (GetStack()->GetTool() != EBrowseTool) ? [NSCursor arrowCursor] : [[[NSCursor alloc] initWithImage: inImage hotSpot: NSMakePoint(xHotSpot, yHotSpot)] autorelease];
		[mView setDocumentCursor: theCursor];
	} );
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
	if( mSearchField)
	{
		if( inEndOffs < inStartOffs )
		{
			NSInteger selStart = 0;
			if( mSearchField.stringValue.length > 0 )
				selStart = mSearchField.stringValue.length -1;
			[mSearchField setSelectedRange: NSMakeRange(selStart,0)];
		}
		else
		{
			NSRange	cocoaRange;
			cocoaRange.location = UTF16OffsetFromUTF32OffsetInCocoaString( inStartOffs -1, mSearchField.stringValue );
			cocoaRange.length = UTF16OffsetFromUTF32OffsetInCocoaString( inEndOffs -1, mSearchField.stringValue ) +1 -cocoaRange.location;
			[mSearchField setSelectedRange: cocoaRange];
		}
	}
	else if( mTableView )
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
	else if( mSearchField )
	{
		NSRange	selRange = [mSearchField selectedRange];
		*outStartOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location, [[mTextView textStorage] string] ) +1;
		*outEndOffs = UTF32OffsetFromUTF16OffsetInCocoaString( selRange.location +selRange.length, [[mTextView textStorage] string] );
		*outType = kLEOChunkTypeCharacter;
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
	if( mAutoSelect && mColumns.size() > 0 )
	{
		NSMutableArray*		lines = [[NSMutableArray alloc] init];
		for( size_t x = 0; x < contents->GetRowCount(); x++ )
		{
			NSMutableArray * cols = [NSMutableArray array];
			size_t	numCols = contents->GetColumnCount( x );
			for( size_t y = 0; y < numCols; y++ )
			{
				NSAttributedString*	attrStr = GetCocoaAttributedString( contents->GetAttributedTextInRowColumn(x, y), GetCocoaAttributesForPart() );
				[cols addObject: attrStr];
			}
			[lines addObject: cols];
		}
		mMacDelegate.multipleColumns = YES;
		[mMacDelegate setLines: lines];
		[lines release];
		[mTableView reloadData];
	}
	else if( mAutoSelect )
	{
		ListChunkCallbackContext	ctx = { .lines = [[NSMutableArray alloc] init], .contents = contents, .defaultAttrs = GetCocoaAttributesForPart() };
		if( contents )
		{
			std::string	theStr( contents->GetText() );
			if( theStr.find("{\\rtf1\\ansi\\") == 0 )	// +++ Remove before shipping, this is to import old Stacksmith beta styles.
			{
				NSDictionary*			docAttrs = nil;
				NSAttributedString*		attrStr = [[NSAttributedString alloc] initWithRTF: [NSData dataWithBytes: theStr.c_str() length: theStr.length()] documentAttributes: &docAttrs];
				CAttributedString&		cppstr = contents->GetAttributedText();
				SetAttributedStringWithCocoa( cppstr, attrStr );
				theStr = contents->GetText();
			}
			LEODoForEachChunk( theStr.c_str(), contents->GetText().length(), kLEOChunkTypeLine, ListChunkCallback, 0, &ctx );
		}
		mMacDelegate.multipleColumns = NO;
		[mMacDelegate setLines: ctx.lines];
		[ctx.lines release];
		[mTableView reloadData];
	}
	else if( contents && mFieldStyle == EFieldStylePopUp )
	{
		ListChunkCallbackContext	ctx = { .lines = [[NSMutableArray alloc] init], .contents = contents, .defaultAttrs = GetCocoaAttributesForPart() };
		if( contents )
		{
			std::string	theStr( contents->GetText() );
			LEODoForEachChunk( theStr.c_str(), contents->GetText().length(), kLEOChunkTypeLine, ListChunkCallback, 0, &ctx );
		}
		mMacDelegate.multipleColumns = NO;
		[mMacDelegate setLines: ctx.lines];
		[ctx.lines release];
		[(WILDComboBox*)mSearchField reloadData];
		[mSearchField setAttributedStringValue: mMacDelegate.lines[0]];
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
		if( mSearchField )
			[mSearchField setAttributedStringValue: attrStr];
		else
		{
			BOOL	oldDontSendSelectionChange = mMacDelegate.dontSendSelectionChange;
			mMacDelegate.dontSendSelectionChange = GetLockText() || oldDontSendSelectionChange;
			[mTextView.textStorage setAttributedString: attrStr];
			mMacDelegate.dontSendSelectionChange = oldDontSendSelectionChange;
		}
	}
	else
	{
		if( mSearchField )
		{
			[mSearchField setStringValue: @""];
			if( mFieldStyle == EFieldStylePopUp )
				mMacDelegate.lines = [NSMutableArray arrayWithObject: [[[NSAttributedString alloc] init] autorelease]];
		}
		else
			[mTextView setString: @""];
	}
}


void	CFieldPartMac::LoadChangedTextFromView()
{
	CPartContents*	contents = GetContentsOnCurrentCard();
	if( contents )
	{
		if( mAutoSelect && mColumns.size() > 0 )
		{
			size_t	x = 0;
			for( NSArray* currRow in mMacDelegate.lines )
			{
				size_t y = 0;
				for( NSAttributedString* attrStr in currRow )
				{
					CAttributedString&	cppstr = contents->GetAttributedTextInRowColumn( x, y );
					if( ![attrStr isKindOfClass: [NSAttributedString class]] )
						attrStr = [[[NSAttributedString alloc] initWithString: (NSString*)attrStr attributes: @{}] autorelease];
					SetAttributedStringWithCocoa( cppstr, attrStr );
					y++;
				}
				
				x++;
			}
		}
		else if( mAutoSelect || mFieldStyle == EFieldStylePopUp )
		{
			NSMutableAttributedString*	finalStr = [[NSMutableAttributedString alloc] init];
			BOOL						firstLine = YES;
			for( NSAttributedString * attrStr in mMacDelegate.lines )
			{
				if( firstLine )
					firstLine = NO;
				else
					[finalStr.mutableString appendString: @"\n"];
				[finalStr appendAttributedString: attrStr];
			}
			CAttributedString&		cppstr = contents->GetAttributedText();
			SetAttributedStringWithCocoa( cppstr, finalStr );
		}
		else if( mSearchField )
		{
			CAttributedString&		cppstr = contents->GetAttributedText();
			NSAttributedString*		attrStr = [mSearchField attributedStringValue];
			SetAttributedStringWithCocoa( cppstr, attrStr );
		}
		else
		{
			CAttributedString&		cppstr = contents->GetAttributedText();
			NSAttributedString*		attrStr = [mTextView textStorage];
			SetAttributedStringWithCocoa( cppstr, attrStr );
		}
	}
	
	mViewTextNeedsSync = false;
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
				else if( currStyle.first.compare("font-style") == 0 && currStyle.second.compare("italic") == 0 )
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
				else if( currStyle.first.compare("color") == 0 )
				{
					if( currStyle.second.size() == 9 && currStyle.second[0] == '#' )
					{
						long	red = strtol( currStyle.second.substr(1,2).c_str(), NULL, 16 ),
								green = strtol( currStyle.second.substr(3,2).c_str(), NULL, 16 ),
								blue = strtol( currStyle.second.substr(5,2).c_str(), NULL, 16 ),
								alpha = strtol( currStyle.second.substr(7,2).c_str(), NULL, 16 );
						[newAttrStr addAttribute: NSForegroundColorAttributeName value: [NSColor colorWithCalibratedRed: red / 255.0 green: green / 255.0 blue: blue / 255.0 alpha: alpha / 255.0] range: currCocoaRange];
					}
//					std::cout << "\tAdded color." << std::endl;
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
					stringToSet.AddAttributeValueForRange( "font-style", "italic", range.location, range.location +range.length );
				}
			//	stringToSet.Dump();
			}
			else if( [currAttr isEqualToString: NSForegroundColorAttributeName] )
			{
				NSColor*	rgbColor = [attrValue colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
				NSString*	colorString = [NSString stringWithFormat: @"#%02X%02X%02X%02X", int(rgbColor.redComponent * 255.0), int(rgbColor.greenComponent * 255.0), int(rgbColor.blueComponent * 255.0), int(rgbColor.alphaComponent * 255.0)];
				stringToSet.AddAttributeValueForRange( "color", colorString.UTF8String, range.location, range.location +range.length );
			//	stringToSet.Dump();
			}
			else if( [currAttr isEqualToString: NSObliquenessAttributeName] && [attrValue integerValue] != 0 )
			{
				stringToSet.AddAttributeValueForRange( "font-style", "italic", range.location, range.location +range.length );
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


void	CFieldPartMac::ToolChangedFrom( TTool inOldTool )
{
	if( (inOldTool != EEditTextTool && GetStack()->GetTool() == EEditTextTool)
		or (inOldTool == EEditTextTool && GetStack()->GetTool() != EEditTextTool) )
	{
		NSView*	oldSuper = (mView? mView : mSearchField).superview;
		DestroyView();
		CreateViewIn( oldSuper );
	}
}


void	CFieldPartMac::SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom )
{
	CFieldPart::SetRect( left, top, right, bottom );
	NSRect		box = ConvertToViewRect(GetLeft(), GetTop(), GetRight(), GetBottom());
	[(mView? mView : mSearchField) setFrame: box];
	GetStack()->RectChangedOfPart( this );
}


NSView*	CFieldPartMac::GetView()
{
	return (mView? mView : mSearchField);
}


void	CFieldPartMac::SetPartLayoutFlags( TPartLayoutFlags inFlags )
{
	CFieldPart::SetPartLayoutFlags( inFlags );
	
	[(mView? mView : mSearchField) setAutoresizingMask: GetCocoaResizeFlags( mPartLayoutFlags )];
}


void	CFieldPartMac::SetScript( std::string inScript )
{
	CFieldPart::SetScript( inScript );
	
	[(mView? mView : mSearchField) updateTrackingAreas];
}

