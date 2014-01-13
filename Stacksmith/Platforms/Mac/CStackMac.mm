//
//  CStackMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStackMac.h"
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#include "CButtonPart.h"
#include "CFieldPart.h"
#include "CMoviePlayerPart.h"
#include "CWebBrowserPart.h"
#include "CTimerPart.h"
#include "CRectanglePart.h"
#include "CPicturePart.h"
#include "CDocument.h"
#include "CAlert.h"
#import "ULIInvisiblePlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "WILDButtonView.h"
#import "WILDButtonCell.h"


using namespace Carlson;


@interface WILDFlippedContentView : NSView

@end

@implementation WILDFlippedContentView

-(BOOL)	isFlipped { return YES; };

@end



@interface WILDButtonOwner : NSViewController

@property (assign,nonatomic) IBOutlet NSButton* systemButton;
@property (assign,nonatomic) IBOutlet WILDButtonView* shapeButton;
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
	CMacPartBase() {};
	
	virtual void	CreateViewIn( NSView* inSuperView ) = 0;
	virtual void	DestroyView() = 0;
	virtual void	ApplyPeekingStateToView( bool inState, NSView* inView )
	{
		//inView.layer.borderWidth = inState? 1 : 0;
		//inView.layer.borderColor = inState? [NSColor grayColor].CGColor : NULL;
	}

protected:
	virtual ~CMacPartBase() {};
};


static WILDButtonOwner*		sButtonOwner = nil;


class CButtonPartMac : public CButtonPart, public CMacPartBase
{
public:
	CButtonPartMac( CLayer *inOwner ) : CButtonPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView()						{ [mView removeFromSuperview]; mView = nil; };
	virtual void	SetName( const std::string& inStr )	{ CButtonPart::SetName(inStr); [mView setTitle: [NSString stringWithUTF8String: mName.c_str()]]; };
	virtual void	SetPeeking( bool inState )	{ ApplyPeekingStateToView(inState, mView); };
	
protected:
	~CButtonPartMac()	{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	
	WILDButtonView	*	mView;
	WILDButtonOwner	*	mButtonOwner;
};


void	CButtonPartMac::CreateViewIn( NSView* inSuperView )
{
	if( !sButtonOwner )
		sButtonOwner = [[WILDButtonOwner alloc] initWithNibName: @"WILDButtonOwner" bundle: nil];
	[sButtonOwner view];
	if( mButtonStyle == EButtonStyleCheckBox )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner systemButton]]] retain];
		[mView setBezelStyle: NSRegularSquareBezelStyle];
		[mView setButtonType: NSSwitchButton];
	}
	else if( mButtonStyle == EButtonStyleRadioButton )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner systemButton]]] retain];
		[mView setBezelStyle: NSRegularSquareBezelStyle];
		[mView setButtonType: NSRadioButton];
	}
	else if( mButtonStyle == EButtonStyleRectangle )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner shapeButton]]] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
	}
	else if( mButtonStyle == EButtonStyleOpaque )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner shapeButton]]] retain];
		[mView setBezelStyle: NSShadowlessSquareBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleRoundrect )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner shapeButton]]] retain];
		[mView setBezelStyle: NSTexturedRoundedBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleStandard )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner systemButton]]] retain];
		[mView setBezelStyle: NSRoundRectBezelStyle];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleDefault )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner systemButton]]] retain];
		[mView setBezelStyle: NSRoundRectBezelStyle];
		[mView setKeyEquivalent: @"\n"];
		[mView setBordered: NO];
	}
	else if( mButtonStyle == EButtonStyleOval )
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner shapeButton]]] retain];
		[mView setBezelStyle: NSCircularBezelStyle];
	}
	else
	{
		mView = [[NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: [sButtonOwner shapeButton]]] retain];
		[mView setBezelStyle: NSRoundedBezelStyle];
	}
	[mView setFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[mView setTitle: [NSString stringWithUTF8String: mName.c_str()]];
	[mView setOwningPart: this];
	if( [mView.cell respondsToSelector: @selector(setLineColor:)] )
	{
		[((WILDButtonCell*)mView.cell) setLineColor: [NSColor colorWithCalibratedRed: (mLineColorRed / 65535.0) green: (mLineColorGreen / 65535.0) blue: (mLineColorBlue / 65535.0) alpha:(mLineColorAlpha / 65535.0)]];
		[((WILDButtonCell*)mView.cell) setBackgroundColor: [NSColor colorWithCalibratedRed: (mFillColorRed / 65535.0) green: (mFillColorGreen / 65535.0) blue: (mFillColorBlue / 65535.0) alpha:(mFillColorAlpha / 65535.0)]];
		[((WILDButtonCell*)mView.cell) setLineWidth: mLineWidth];
	}
	[mView setEnabled: mEnabled];
	[inSuperView addSubview: mView];
};


class CFieldPartMac : public CFieldPart, public CMacPartBase
{
public:
	CFieldPartMac( CLayer *inOwner ) : CFieldPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	virtual void	SetPeeking( bool inState )	{ ApplyPeekingStateToView(inState, mView); };
	
protected:
	~CFieldPartMac()	{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	
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
	[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
	[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
	[mView.layer setShadowRadius: mShadowBlurRadius];
	[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
	[inSuperView addSubview: mView];
}


class CMoviePlayerPartMac : public CMoviePlayerPart, public CMacPartBase
{
public:
	CMoviePlayerPartMac( CLayer *inOwner ) : CMoviePlayerPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView )
	{
		if( mView )
			[mView release];
		mView = [[ULIInvisiblePlayerView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
		[mView setWantsLayer: YES];
		mView.layer.masksToBounds = NO;
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
		[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, -mShadowOffsetHeight)];
		[mView.layer setShadowRadius: mShadowBlurRadius];
		[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
		mView.player = [AVPlayer playerWithURL: [[NSBundle mainBundle] URLForResource: @"PlaceholderMovie" withExtension: @"mov"]];
		[inSuperView addSubview: mView];
	};
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	virtual void	SetPeeking( bool inState )	{ ApplyPeekingStateToView(inState, mView); };

protected:
	~CMoviePlayerPartMac()	{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	
	ULIInvisiblePlayerView	*	mView;
};

class CWebBrowserPartMac : public CWebBrowserPart, public CMacPartBase
{
public:
	CWebBrowserPartMac( CLayer *inOwner ) : CWebBrowserPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView )
	{
		if( mView )
			[mView release];
		mView = [[WebView alloc] initWithFrame: NSMakeRect(mLeft, mTop, mRight -mLeft, mBottom -mTop)];
		NSURLRequest*	theRequest = [NSURLRequest requestWithURL: [NSURL URLWithString: @"http://hammer-language.com"]];
		[mView.mainFrame loadRequest: theRequest];
		[mView setWantsLayer: YES];
		[mView.layer setShadowColor: [NSColor colorWithCalibratedRed: (mShadowColorRed / 65535.0) green: (mShadowColorGreen / 65535.0) blue: (mShadowColorBlue / 65535.0) alpha:(mShadowColorAlpha / 65535.0)].CGColor];
		[mView.layer setShadowOffset: CGSizeMake(mShadowOffsetWidth, mShadowOffsetHeight)];
		[mView.layer setShadowRadius: mShadowBlurRadius];
		[mView.layer setShadowOpacity: mShadowColorAlpha == 0 ? 0.0 : 1.0];
		[inSuperView addSubview: mView];
	};
	virtual void	DestroyView()						{ [mView removeFromSuperview]; [mView release]; mView = nil;
	};
	virtual void	SetPeeking( bool inState )	{ ApplyPeekingStateToView(inState, mView); };

protected:
	~CWebBrowserPartMac()	{ [mView removeFromSuperview]; [mView release]; mView = nil; };
	
	WebView	*	mView;
};



@interface WILDStackWindowController : NSWindowController <NSWindowDelegate>
{
	CStackMac	*	mStack;
	CALayer		*	mSelectionOverlay;	// Draw "peek" outline and selection rectangles in this layer.
	NSImageView	*	mBackgroundImageView;
	NSImageView	*	mCardImageView;
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


-(void)	dealloc
{
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	
	[super dealloc];
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
	
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
}

-(void)	createAllViews
{
	[mBackgroundImageView removeFromSuperview];
	[mBackgroundImageView release];
	mBackgroundImageView = nil;
	[mCardImageView removeFromSuperview];
	[mCardImageView release];
	mCardImageView = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	CBackground	*	theBackground = theCard->GetBackground();
	std::string		bgPictureURL( theBackground->GetPictureURL() );
	if( theBackground->GetShowPicture() && bgPictureURL.length() > 0 )
	{
		mBackgroundImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
		[mBackgroundImageView setWantsLayer: YES];
		mBackgroundImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: bgPictureURL.c_str()]]] autorelease];
		[self.window.contentView addSubview: mBackgroundImageView];
	}
	
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBackground->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( self.window.contentView );
	}

	numParts = theCard->GetNumParts();
	std::string		cdPictureURL( theCard->GetPictureURL() );
	if( theCard->GetShowPicture() && cdPictureURL.length() > 0 )
	{
		mCardImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
		[mCardImageView setWantsLayer: YES];
		mCardImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cdPictureURL.c_str()]]] autorelease];
		[self.window.contentView addSubview: mCardImageView];
	}
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( self.window.contentView );
	}
	
	[self drawBoundingBoxes];
}


-(void)	drawBoundingBoxes
{
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	if( mStack->GetDocument()->GetPeeking() )
	{
		CGColorSpaceRef	colorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );
		CGContextRef	bmContext = CGBitmapContextCreate( NULL, mStack->GetCardWidth(), mStack->GetCardHeight(), 8, mStack->GetCardWidth() * 8 * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little );
		CGColorSpaceRelease(colorSpace);
		NSGraphicsContext	*	cocoaContext = [NSGraphicsContext graphicsContextWithGraphicsPort: bmContext flipped: NO];
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext: cocoaContext];
		
		[[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] set];
		[NSBezierPath setDefaultLineWidth: 1];
		
		size_t		cardHeight = mStack->GetCardHeight();
		
		CBackground	*	theBackground = theCard->GetBackground();
		size_t	numParts = theBackground->GetNumParts();
		for( size_t x = 0; x < numParts; x++ )
		{
			CPart*	currPart = theBackground->GetPart(x);
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}

		numParts = theCard->GetNumParts();
		for( size_t x = 0; x < numParts; x++ )
		{
			CPart*	currPart = theCard->GetPart(x);
			[NSBezierPath strokeRect: NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 )];
		}

		mSelectionOverlay = [[CALayer alloc] init];
		[[self.window.contentView layer] addSublayer: mSelectionOverlay];
		[mSelectionOverlay setFrame: [self.window.contentView layer].frame];
		
		[NSGraphicsContext restoreGraphicsState];
		CGImageRef	bmImage = CGBitmapContextCreateImage( bmContext );
		mSelectionOverlay.contents = [(id)bmImage autorelease];
		
		CFRelease(bmContext);
	}
}

@end


CStackMac::CStackMac( const std::string& inURL, ObjectID inID, const std::string& inName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inDocument )
{
	mMacWindowController = nil;
}


bool	CStackMac::GoThereInNewWindow( bool inNewWindow )
{
	if( !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
	[mMacWindowController showWindow: nil];
	GetCurrentCard()->SendMessage( NULL, [](const char* errMsg,size_t,size_t,CScriptableObject*) { if( errMsg ) CAlert::RunMessageAlert(errMsg); }, "openStack" );
	GetCurrentCard()->SendMessage( NULL, [](const char* errMsg,size_t,size_t,CScriptableObject*) { if( errMsg ) CAlert::RunMessageAlert(errMsg); }, "openCard" );
	
	return true;
}


void	CStackMac::SetPeeking( bool inState )
{
	CStack::SetPeeking( inState );
	[mMacWindowController drawBoundingBoxes];
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
