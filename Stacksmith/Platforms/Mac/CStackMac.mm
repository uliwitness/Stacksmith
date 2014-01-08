//
//  CStackMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStackMac.h"
#import <AppKit/AppKit.h>
#include "CButtonPart.h"
#include "CFieldPart.h"
#include "CMoviePlayerPart.h"
#include "CWebBrowserPart.h"
#include "CTimerPart.h"
#include "CRectanglePart.h"
#include "CPicturePart.h"


using namespace Carlson;


@interface WILDFlippedContentView : NSView

@end

@implementation WILDFlippedContentView

-(BOOL)	isFlipped { return YES; };

@end



@interface WILDButtonOwner : NSViewController

@property (assign,nonatomic) IBOutlet NSButton* button;
@property (assign,nonatomic) IBOutlet NSTextField* textField;

@end


@implementation WILDButtonOwner

-(IBAction)	buttonClicked: (id)sender
{
	NSLog(@"Button %@ clicked.", [sender title]);
}

@end


class CMacPartBase
{
public:
	virtual void	CreateViewIn( NSView* inSuperView ) = 0;
	virtual void	DestroyView() = 0;

	virtual ~CMacPartBase() {};
};


static WILDButtonOwner*		sButtonOwner = nil;


class CButtonPartMac : public CButtonPart, public CMacPartBase
{
public:
	CButtonPartMac( CLayer *inOwner ) : CButtonPart( inOwner ), mView(nil) {};
	~CButtonPartMac()	{ [mView release]; mView = nil; };

	virtual void	CreateViewIn( NSView* inSuperView )	{ if( !sButtonOwner ) sButtonOwner = [[WILDButtonOwner alloc] initWithNibName: @"WILDButtonOwner" bundle: nil]; [sButtonOwner view]; mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner button]]] retain]; [mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)]; [mView.layer setShadowColor: [NSColor.redColor CGColor]]; [mView.layer setShadowOffset: CGSizeMake(4, 4)]; [mView.layer setShadowRadius: 8]; [mView.layer setShadowOpacity: 1.0]; [mView setBezelStyle: NSRoundRectBezelStyle]; [mView setTitle: [NSString stringWithUTF8String: mName.c_str()]]; [inSuperView addSubview: mView]; };
	virtual void	DestroyView()						{ [mView removeFromSuperview]; mView = nil; };
	virtual void	SetName( const std::string& inStr )	{ CButtonPart::SetName(inStr); [mView setTitle: [NSString stringWithUTF8String: mName.c_str()]]; };
	
	NSButton		*	mView;
	WILDButtonOwner	*	mButtonOwner;
};


class CFieldPartMac : public CFieldPart, public CMacPartBase
{
public:
	CFieldPartMac( CLayer *inOwner ) : CFieldPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	
	NSTextField	*	mView;
};


void	CFieldPartMac::CreateViewIn( NSView* inSuperView )
{
	if( !sButtonOwner )
		sButtonOwner = [[WILDButtonOwner alloc] initWithNibName: @"WILDButtonOwner" bundle: nil];
	[sButtonOwner view];
	mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner textField]]] retain];
	CPartContents*	contents = GetContentsOnCurrentCard();
	std::string		cppstr = contents? contents->GetText() : std::string();
	[mView setStringValue: [NSString stringWithUTF8String: cppstr.c_str()]];
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor.redColor CGColor]];
	[mView.layer setShadowOffset: CGSizeMake(4, 4)];
	[mView.layer setShadowRadius: 8];
	[mView.layer setShadowOpacity: 1.0];
	[inSuperView addSubview: mView];
}


class CMoviePlayerPartMac : public CMoviePlayerPart, public CMacPartBase
{
public:
	CMoviePlayerPartMac( CLayer *inOwner ) : CMoviePlayerPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView )	{ if( mView ) [mView release]; mView = [[NSBox alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)]; [mView setBoxType: NSBoxCustom]; [mView setTitlePosition: NSNoTitle];
	[mView setFillColor: [NSColor whiteColor]];
	[mView setLayerUsesCoreImageFilters: YES];
	[mView setWantsLayer: YES];
	mView.layer.masksToBounds = NO;
	[mView.layer setShadowColor: [NSColor.redColor CGColor]];
	[mView.layer setShadowOffset: CGSizeMake(4, -4)];
	[mView.layer setShadowRadius: 8];
	[mView.layer setShadowOpacity: 1.0];
[inSuperView addSubview: mView]; };
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
		
	NSBox	*	mView;
};

class CWebBrowserPartMac : public CWebBrowserPart, public CMacPartBase
{
public:
	CWebBrowserPartMac( CLayer *inOwner ) : CWebBrowserPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView )	{ if( mView ) [mView release]; mView = [[NSBox alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)]; [(NSBox*)mView setBoxType: NSBoxCustom]; [(NSBox*)mView setTitlePosition: NSNoTitle];
	[mView setLayerUsesCoreImageFilters: YES];
	[mView setWantsLayer: YES];
	mView.layer.masksToBounds = NO;
	[mView.layer setShadowColor: [NSColor.redColor CGColor]];
	[mView.layer setShadowOffset: CGSizeMake(4, -4)];
	[mView.layer setShadowRadius: 8];
	[mView.layer setShadowOpacity: 1.0];
[inSuperView addSubview: mView]; };
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
		
	NSView	*	mView;
};



@interface WILDStackWindowController : NSWindowController <NSWindowDelegate>
{
	CStackMac	*	mStack;
}

-(id)	initWithCppStack: (CStackMac*)inStack;

-(void)	removeAllViews;
-(void)	createAllViews;

@end

@implementation WILDStackWindowController

-(id)	initWithCppStack: (CStackMac*)inStack
{
	NSRect			wdBox = NSMakeRect(0,0,inStack->GetCardWidth(),inStack->GetCardHeight());
	NSWindow	*	theWindow = [[[NSWindow alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
	NSView*	cv = [[[WILDFlippedContentView alloc] initWithFrame: wdBox] autorelease];
	cv.wantsLayer = YES;
	[cv setLayerUsesCoreImageFilters: YES];
	theWindow.contentView = cv;
	[theWindow setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[theWindow setTitle: [NSString stringWithUTF8String: inStack->GetName().c_str()]];
	[theWindow setRepresentedURL: [NSURL URLWithString: [NSString stringWithUTF8String: inStack->GetURL().c_str()]]];
	[theWindow center];
	[theWindow setDelegate: self];

	self = [super initWithWindow: theWindow];
	if( self )
	{
		mStack = inStack;
	}
	
	return self;
}

-(void)	removeAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->DestroyView();
	}
}

-(void)	createAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( self.window.contentView );
	}
}

@end


CStackMac::CStackMac( const std::string& inURL, WILDObjectID inID, const std::string& inName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inDocument )
{
	mMacWindowController = nil;
}


bool	CStackMac::GoThereInNewWindow( bool inNewWindow )
{
	if( !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
	[mMacWindowController showWindow: nil];
	
	return true;
}


void	CStackMac::SetCurrentCard( CCard* inCard )
{
	if( !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];

	[mMacWindowController removeAllViews];
	
	CStack::SetCurrentCard(inCard);
	
	[mMacWindowController createAllViews];
}


void	CStackMac::RegisterPartCreators()
{
	static bool	sAlreadyDidThis = false;
	if( !sAlreadyDidThis )
	{
		CPart::RegisterPartCreator( new CPartCreator<CButtonPartMac>( "button" ) );
		CPart::RegisterPartCreator( new CPartCreator<CFieldPartMac>( "field" ) );
		CPart::RegisterPartCreator( new CPartCreator<CWebBrowserPartMac>( "browser" ) );
		CPart::RegisterPartCreator( new CPartCreator<CMoviePlayerPartMac>( "moviePlayer" ) );
		CPart::RegisterPartCreator( new CPartCreator<CTimerPart>( "timer" ) );
		CPart::RegisterPartCreator( new CPartCreator<CRectanglePart>( "rectangle" ) );
		CPart::RegisterPartCreator( new CPartCreator<CPicturePart>( "picture" ) );
		
		sAlreadyDidThis = true;
	}
}
