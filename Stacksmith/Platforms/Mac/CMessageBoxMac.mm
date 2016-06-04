//
//  CMessageBoxMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-17.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMessageBoxMac.h"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


using namespace Carlson;


@interface WILDMessageBoxWindowController : NSWindowController

@property (assign,nonatomic) IBOutlet NSTextView	*	messageField;
@property (assign,nonatomic) IBOutlet NSTextField	*	resultField;
@property (assign,nonatomic) IBOutlet NSButton		*	runButton;
@property (retain,nonatomic) NSMutableArray			*	messageHistory;
@property (assign,nonatomic) CMessageBoxMac			*	messageBox;

@end


@implementation WILDMessageBoxWindowController

-(void)	dealloc
{
	self.messageHistory = nil;
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	//[self.window setLevel: NSNormalWindowLevel];
	self.messageField.automaticQuoteSubstitutionEnabled = NO;
	self.messageField.automaticDashSubstitutionEnabled = NO;
	self.messageField.automaticTextReplacementEnabled = NO;
	
	_messageHistory = [[[NSUserDefaults standardUserDefaults] objectForKey: @"WILDMessageHistory"] mutableCopy];
	if( !_messageHistory )
		_messageHistory = [NSMutableArray new];
}


-(IBAction) run: (id)sender
{
	NSString	*	commandToRun = [[self.messageField.string copy] autorelease];
	if( ![self.messageHistory containsObject: commandToRun] )
	{
		if( commandToRun.length > 0 )
			[self.messageHistory addObject: commandToRun];
		if( self.messageHistory.count > 20 )
		{
			[self.messageHistory removeObjectsInRange: NSMakeRange(0,self.messageHistory.count -20)];
		}
		[[NSUserDefaults standardUserDefaults] setObject: self.messageHistory forKey: @"WILDMessageHistory"];
	}
	self.messageBox->SetResultText( "" );
	self.messageBox->SetTextContents( [commandToRun UTF8String] );
	self.messageBox->Run();
}


-(void)	windowWillClose: (NSNotification *)notification
{
	self.messageBox->UpdateVisible(false);
}


-(BOOL) textView: (NSTextView *)textView doCommandBySelector: (SEL)commandSelector
{
	if( commandSelector == @selector(insertNewline:) )
	{
		[self.runButton performClick: self];
		return YES;
	}
	else if( commandSelector == @selector(moveUp:) )
	{
		NSRange	selection = self.messageField.selectedRange;
		if( selection.location != 0 || selection.length != 0 )	// Give user opportunity to go to start of line first.
		{
			return NO;
		}
		else
		{
			NSString	*currMsg = [[self.messageField.string copy] autorelease];
			NSUInteger	currLineIdx = [self.messageHistory indexOfObject: currMsg];
			if( currLineIdx == NSNotFound )
			{
				if( self.messageHistory.count > 0 )	// We're at bottom of history
				{
					if( currMsg.length == 0 )	// Empty line? Just go up into history.
						currLineIdx = self.messageHistory.count -1;
					else
					{
						[self.messageHistory addObject: currMsg];	// Don't lose whatever user typed so far.
						[[NSUserDefaults standardUserDefaults] setObject: self.messageHistory forKey: @"WILDMessageHistory"];
						currLineIdx = self.messageHistory.count -2;
					}
				}
				else
					return NO;
			}
			else if( currLineIdx == 0 )
				return NO;
			else
				currLineIdx --;
			
			self.messageField.string = self.messageHistory[currLineIdx];
			self.messageField.selectedRange = (NSRange){0,0};
			return YES;
		}
	}
	else if( commandSelector == @selector(moveDown:) )
	{
		NSString	*currMsg = [[self.messageField.string copy] autorelease];
		NSRange	selection = self.messageField.selectedRange;
		if( selection.location != currMsg.length || selection.length != 0 )	// Give user opportunity to go to start of line first.
		{
			return NO;
		}
		else
		{
			NSUInteger	currLineIdx = [self.messageHistory indexOfObject: currMsg];
			if( self.messageHistory.count == 0 || currLineIdx == (self.messageHistory.count -1)
				|| currLineIdx == NSNotFound )
			{
				if( currMsg.length == 0 )	// Empty line and no history? Nothing to do.
					return NO;
				else	// Non-empty line? Put this line in history and give user an empty line:
				{
					if( currLineIdx == NSNotFound )
					{
						[self.messageHistory addObject: currMsg];	// Don't lose whatever user typed so far.
						[[NSUserDefaults standardUserDefaults] setObject: self.messageHistory forKey: @"WILDMessageHistory"];
					}
					self.messageField.string = @"";
					return YES;
				}
			}
			else
				currLineIdx ++;
			
			self.messageField.string = self.messageHistory[currLineIdx];
			return YES;
		}
	}
	else
	{
		//NSLog(@"%@", NSStringFromSelector(commandSelector));
		return NO;
	}
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray<NSValue *> *)affectedRanges replacementStrings:(nullable NSArray<NSString *> *)replacementStrings
{
	self.messageBox->SetNeedsToSyncContentsFromUI( true );
	
	return YES;
}

@end


CMessageBoxMac::CMessageBoxMac()
	: mVisible(false), mNeedsToSyncContentsFromUI(false)
{
	mMacWindowController = [[WILDMessageBoxWindowController alloc] initWithWindowNibName: @"WILDMessageBoxWindowController"];
	mMacWindowController.messageBox = this;
	
#if 0
	[mMacWindowController.window.contentView setLayerUsesCoreImageFilters: YES];
	CIFilter	*	theFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
	[theFilter setDefaults];
	[theFilter setValue: @3.0 forKey: @"inputRadius"];
	[[mMacWindowController.window.contentView layer] setBackgroundFilters: @[theFilter]];
#else
	[mMacWindowController.window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.3 alpha: 0.7]];
#endif
	
	// We first set a space, because we need to set some string or the field will ignore our styles:
	NSMutableAttributedString	*	attrStr = [[[NSMutableAttributedString alloc] initWithString: @" " attributes:@{ NSForegroundColorAttributeName: NSColor.whiteColor, NSFontAttributeName: [NSFont userFixedPitchFontOfSize: 12.0] }] autorelease];
	[mMacWindowController.messageField.textStorage setAttributedString: attrStr];
	// Now set it to an empty string, which is how we expect our window to start out:
	[attrStr.mutableString setString: @""];
	[mMacWindowController.messageField.textStorage setAttributedString: attrStr];
}


CMessageBoxMac::~CMessageBoxMac()
{
	[mMacWindowController close];
	[mMacWindowController release];
	mMacWindowController = nil;
}


bool	 CMessageBoxMac::GetTextContents( std::string &outString )
{
	if( mNeedsToSyncContentsFromUI )
	{
		mScript = mMacWindowController.messageField.string.UTF8String;
		mNeedsToSyncContentsFromUI = false;
	}
	
	return CMessageBox::GetTextContents( outString );
}


bool	CMessageBoxMac::SetTextContents( const std::string& inString )
{
	CMessageBox::SetTextContents( inString );
	
	NSString	*	str = [NSString stringWithUTF8String: inString.c_str()];
	NSMutableAttributedString	*	attrStr = [[[NSMutableAttributedString alloc] initWithString: str attributes:@{ NSForegroundColorAttributeName: NSColor.whiteColor, NSFontAttributeName: [NSFont userFixedPitchFontOfSize: 12.0] }] autorelease];
	[mMacWindowController.messageField.textStorage setAttributedString: attrStr];
	[mMacWindowController.window makeKeyAndOrderFront: nil];
	mVisible = true;
	[mMacWindowController.messageField setSelectedRange: NSMakeRange( mMacWindowController.messageField.string.length, 0)];
	[mMacWindowController.window display];
	
	return true;
}


bool	CMessageBoxMac::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		const char*	msgName = [mMacWindowController.window.title UTF8String];
		LEOInitStringValue( outValue, msgName, strlen(msgName), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, mScript.c_str(), mScript.size(), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		NSRect	box = [mMacWindowController.window contentRectForFrameRect: [mMacWindowController.window frame]];
		NSRect	mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		LEOInitRectValue( outValue, NSMinX(box), NSMinY(box), NSMaxX(box), NSMaxY(box), kLEOInvalidateReferences, inContext );
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		LEOInitBooleanValue( outValue, mVisible, kLEOInvalidateReferences, inContext );
	}
	else
		return CMessageBox::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CMessageBoxMac::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("name", inPropertyName) == 0 || strcasecmp("short name", inPropertyName) == 0 )
	{
		char		nameBuf[1024];
		const char*	nameStr = LEOGetValueAsString( inValue, nameBuf, sizeof(nameBuf), inContext );
		[mMacWindowController.window setTitle: [NSString stringWithUTF8String: nameStr]];
	}
	else if( strcasecmp("script", inPropertyName) == 0 )
	{
		char		scriptBuf[1024];
		const char*	scriptStr = LEOGetValueAsString( inValue, scriptBuf, sizeof(scriptBuf), inContext );
		SetTextContents( scriptStr );
	}
	else if( strcasecmp("rectangle", inPropertyName) == 0 || strcasecmp("rect", inPropertyName) == 0 )
	{
		LEOInteger	l, t, r, b;
		LEOGetValueAsRect( inValue, &l, &t, &r, &b, inContext);
		NSRect		box = { { (CGFloat)l, (CGFloat)t }, { (CGFloat)r - l, (CGFloat)b - t } };
		NSRect		mainScreenBox = [[NSScreen.screens objectAtIndex: 0] frame];
		box.origin.y = mainScreenBox.size.height -box.origin.y;
		
		[mMacWindowController.window setFrame: box display: YES];
	}
	else if( strcasecmp("visible", inPropertyName) == 0 )
	{
		bool	isVisible = LEOGetValueAsBoolean( inValue, inContext );
		if( isVisible )
			[mMacWindowController.window makeKeyAndOrderFront: nil];
		else
			[mMacWindowController.window orderOut: nil];
		mVisible = isVisible;
	}
	else
		return CMessageBox::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CMessageBoxMac::SetVisible( bool n )
{
	if( n )
		[mMacWindowController.window makeKeyAndOrderFront: nil];
	else
		[mMacWindowController.window orderOut: nil];
	mVisible = n;
}


void	CMessageBoxMac::SetResultText( const std::string &inString )
{
	CMessageBox::SetResultText( inString );
	[mMacWindowController.resultField setStringValue: [NSString stringWithUTF8String: inString.c_str()]];
}


