//
//  CDocumentMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CDocumentMac.h"
#include "CStackMac.h"
#include "CAlert.h"
#import "UKHelperMacros.h"
#include <sstream>
#import "WILDStackWindowController.h"
#import "WILDStackCanvasWindowController.h"
#include "CCompletionBlockCoalescer.h"
#include "CMenuMac.h"
#import "WILDConcreteObjectInfoViewController.h"
#import <Cocoa/Cocoa.h>


using namespace Carlson;


CDocumentMac*	CDocumentManagerMac::sCurrentMenuBarOwner = nullptr;



CStack*		CDocumentMac::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
{
	return new CStackMac( inURL, inID, inName, inFileName, inDocument );
}


void	CDocumentManagerMac::OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup, TOpenInvisibly openInvisibly )
{
    try
    {
        //UKLog(@"Entered");
		bool		isFromNetwork = inGroup && (inGroup->flags & kLEOContextGroupFlagFromNetwork);
		bool		networkForbidden = inGroup && (inGroup->flags & kLEOContextGroupFlagNoNetwork);
		if( !networkForbidden ) networkForbidden = isFromNetwork;	// Files from network must be self-contained and may not open other files.
        
        std::string		fileURL( inURL );
		if( fileURL.length() > 0 && fileURL[fileURL.length() -1] != '/' )
			fileURL.append( 1, '/' );
        fileURL.append("project.xml");
        size_t	foundPosStack = fileURL.find("x-stack://");
        size_t	foundPosFile = fileURL.find("file://");
        size_t	foundPosHttp = fileURL.find("http://");
        size_t	foundPosHttps = fileURL.find("https://");
        size_t	foundPosStacks = fileURL.find("x-stacks://");
        if( foundPosStack == 0 )	// x-stack URL?
		{
			if( isFromNetwork || networkForbidden )
			{
				inCompletionBlock(nullptr);
				return;
			}
            fileURL.replace(foundPosStack, 10, "http://");
		}
        else if( foundPosStacks == 0 )	// x-stacks URL?
		{
			if( isFromNetwork || networkForbidden )
			{
				inCompletionBlock(nullptr);
				return;
			}
            fileURL.replace(foundPosStacks, 10, "https://");
		}
		else if( foundPosHttp == 0 && (isFromNetwork || networkForbidden) )
		{
			inCompletionBlock(nullptr);
			return;
		}
		else if( foundPosHttps == 0 && (isFromNetwork || networkForbidden) )
		{
			inCompletionBlock(nullptr);
			return;
		}
        else if( foundPosFile == 0 )	// Local file URL.
        {
			if( isFromNetwork )
			{
				inCompletionBlock(nullptr);
				return;
			}
            NSError		*		err = nil;
            if( ![[NSURL URLWithString: [NSString stringWithUTF8String: fileURL.c_str()]]checkResourceIsReachableAndReturnError: &err] )	// File not found?
            {
                fileURL = inURL;
				if( fileURL.length() > 0 && fileURL[fileURL.length() -1] != '/' )
					fileURL.append( 1, '/' );
                fileURL.append("toc.xml");	// +++ old betas used toc.xml for the main file.
            }
        }
		
		size_t			slashOffset = fileURL.rfind( '/' );
		if( slashOffset == std::string::npos )
			slashOffset = 0;
		std::string		slashlessFileURL = fileURL.substr(0,slashOffset);
		
		// If the document already exists, open the stack:
		for( auto currDoc : mOpenDocuments )
		{
			if( currDoc->GetURL().compare( slashlessFileURL ) == 0 )	// Already open?
			{
				if( currDoc->GetScriptContextGroupObject() == inGroup || inGroup == nullptr )
				{
					if( openInvisibly == EOpenVisibly )
					{
						size_t	numStacks = currDoc->GetNumStacks();
						for( size_t x = 0; x < numStacks; x++ )
						{
							if( currDoc->GetStack(x)->IsVisible() )
							{
								currDoc->GetStack(x)->GetCard(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [currDoc,inCompletionBlock](){ inCompletionBlock(currDoc); }, inEffectType, inSpeed );
							}
						}
					}
					else
					{
						inCompletionBlock(currDoc);
					}
					[NSDocumentController.sharedDocumentController noteNewRecentDocumentURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]];
					return;
				}
				else	// Another context group already has it open?
				{
					inCompletionBlock( nullptr );
					return;
				}
			}
		}
		
		// Wasn't already open? Create a new one and load the URL into it:
        mOpenDocuments.push_back( new CDocumentMac(inGroup) );
        CDocumentRef	currDoc( mOpenDocuments.back(), true );	// Take over ownership of the pointer we just 'new'ed, mOpenDocuments retains it by itself.
        
        currDoc->LoadFromURL( fileURL, [this,inCompletionBlock,inURL,inEffectType,inSpeed,openInvisibly](Carlson::CDocument * inDocument)
        {
			NSString*	urlStr = [[[NSBundle mainBundle] bundleURL] absoluteString];
			if( [urlStr characterAtIndex: urlStr.length -1] != '/' )
			{
				urlStr = [urlStr stringByAppendingString: @"/"];	// Make sure it ends in a slash so we don't grab folders next to the app.
			}
			if( inURL.find( [urlStr UTF8String] ) == 0 )	// Built-in stack?
				inDocument->SetWriteProtected(true);
			
            //UKLog(@"Doc completion entered");
			size_t	numStacks = inDocument->GetNumStacks();
			std::shared_ptr<CCompletionBlockCoalescer<CDocument*>>	completionBlockObj( std::make_shared<CCompletionBlockCoalescer<CDocument*>>( numStacks, [inCompletionBlock](CDocument*doc)
			{
				if( !CDocumentManager::GetSharedDocumentManager()->GetDidSendStartup() )
				{
					CDocumentManager::GetSharedDocumentManager()->SetDidSendStartup(true);
					doc->SendMessage( nullptr, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject * obj, bool wasHandled){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, EMayGoUnhandled, "startUp" );
					inCompletionBlock(doc);
				}
			} ) );
			for( size_t x = 0; x < numStacks; x++ )
			{
				Carlson::CStack		*		theCppStack = inDocument->GetStack( x );
				if( !theCppStack )
				{
					UKLog(@"No stacks in project %p", inDocument);
					CloseDocument( inDocument );
					completionBlockObj->Abort(nullptr);
					return;
				}
				theCppStack->Load( [this,inDocument,completionBlockObj,inURL,inEffectType,inSpeed,openInvisibly](Carlson::CStack* inStack)
				{
					//UKLog(@"Stack completion entered %p", inStack);
					//inStack->Dump();
					if( !inStack->IsLoaded() )
					{
						CloseDocument( inDocument );
						UKLog(@"Error loading stack for document %p", inDocument);
						completionBlockObj->Abort(nullptr);
						return;
					}
					CCard	*	firstCard = (inStack ? inStack->GetCard(0) : NULL);
					//UKLog(@"Stack completion entered (2) %p in %p", firstCard, inStack);
					firstCard->Load( [this,inDocument,inStack,completionBlockObj,inURL,inEffectType,inSpeed,openInvisibly](Carlson::CLayer*inCard)
					{
						//UKLog(@"Card completion entered %p",inCard);
						if( inCard )
						{
							if( openInvisibly == EOpenVisibly )
							{
								inCard->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [inDocument,completionBlockObj,inURL,inEffectType,inSpeed](){ [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]]; completionBlockObj->Success(inDocument); }, inEffectType, inSpeed );
							}
							else
								completionBlockObj->Success(inDocument);
						}
						else
						{
							CloseDocument( inDocument );
							completionBlockObj->Abort(nullptr);
						}
						//UKLog(@"Card completion exited");
					} );
					//UKLog(@"Stack completion exited");
				} );
			}
            //UKLog(@"Doc completion exited");
        });

        //UKLog(@"Exited");
    }
    catch( std::exception& inException )
    {
        UKLog( @"Exception caught: %s", inException.what() );
        inCompletionBlock(NULL);
    }
    catch( ... )
    {
        UKLog( @"Unknown exception caught" );
        inCompletionBlock(NULL);
    }
}


void	CDocumentManagerMac::Quit()
{
	[[NSApplication sharedApplication] terminate: nil];
}


CDocumentMac::~CDocumentMac()
{
	if( CDocumentManagerMac::sCurrentMenuBarOwner == this )
		CDocumentManagerMac::sCurrentMenuBarOwner = nullptr;
	[mMacMenus release];
	mMacMenus = nil;
}


CMenu*	CDocumentMac::NewMenuWithElement( tinyxml2::XMLElement* inMenuXML, TMenuMarkChangedFlag inMarkChanged )
{
	CMenu	*	theMenu = new CMenuMac( this );
	theMenu->LoadFromElement( inMenuXML );
	mMenus.push_back( theMenu );
	theMenu->Autorelease();
	
	if( inMarkChanged == EMenuMarkChanged )
		IncrementChangeCount();
	
	if( CDocumentManagerMac::sCurrentMenuBarOwner == this )
	{
		AddMacMenuForMenu( theMenu );
	}
	
	return theMenu;
}


void	CDocumentMac::AddMacMenuForMenu( CMenu* currMenu )
{
	CStackMac*		mainStack = (CStackMac*) CStack::GetMainStack();
	if( !mainStack )
		mainStack = (CStackMac*) CStack::GetFrontStack();
	
	CMenuMac*	macMenu = dynamic_cast<CMenuMac*>(currMenu);
	WILDStackWindowController* menuDelegate = mainStack->GetMacWindowController();
	NSMenu * theMacMenu = macMenu->GetMacMenu();
	if( theMacMenu.delegate != menuDelegate )
	{
		theMacMenu.delegate = menuDelegate;
		[theMacMenu.itemArray makeObjectsPerformSelector: @selector(setTarget:) withObject: menuDelegate];
	}
	NSMenuItem* menuTitleItem = macMenu->GetOwningMacMenuItem();
	[[[NSApplication sharedApplication] mainMenu] addItem: menuTitleItem];
	[GetMacMenus() addObject: menuTitleItem];
}


void	CDocumentMac::RemoveMacMenus()
{
	for( NSMenuItem* currMacMenuParentItem : mMacMenus )
	{
		[currMacMenuParentItem.menu removeItem: currMacMenuParentItem];
	}
	[mMacMenus removeAllObjects];
	CDocumentManagerMac::sCurrentMenuBarOwner = nullptr;
}


void	CDocumentMac::SetIndexOfMenu( CMenu* inMenu, LEOInteger inIndex )
{
	CMenuMac * macMenu = dynamic_cast<CMenuMac*>(inMenu);
	NSMenuItem * macMenuItem = macMenu->GetOwningMacMenuItem();
	NSMenu * mainMenu = macMenuItem.menu;
	NSUInteger indexOffset = [mainMenu indexOfItem: macMenuItem] -GetIndexOfMenu(inMenu);	// Account for built-in non-script-created menus.
	[mainMenu removeItem: macMenuItem];
	[mainMenu insertItem: macMenuItem atIndex: indexOffset +inIndex];
	
	CDocument::SetIndexOfMenu( inMenu, inIndex );
}


void	CDocumentMac::ShowStackCanvasWindow()
{
	if( !mCanvasWindowController )
	{
		mCanvasWindowController = [[WILDStackCanvasWindowController alloc] initWithWindowNibName: @"WILDStackCanvasWindowController"];
		mCanvasWindowController.owningDocument = this;
		[mCanvasWindowController showWindow: nil];
	}
	else if( mCanvasWindowController.window == [NSApplication.sharedApplication mainWindow] )
		[mCanvasWindowController.window orderOut: nil];
	else
		[mCanvasWindowController.window makeKeyAndOrderFront: nil];
}


void	CDocumentMac::IncrementChangeCount()
{
	CDocument::IncrementChangeCount();
	if( mCanvasWindowController )
		[mCanvasWindowController reloadData];
}


void	CDocumentMac::MenuIncrementedChangeCount( CMenuItem* inItem, CMenu* inMenu, bool parentNeedsFullRebuild )
{
	CDocument::MenuIncrementedChangeCount( inItem, inMenu, parentNeedsFullRebuild );
}


void	CDocumentMac::StackIncrementedChangeCount( CStack* inStack )
{
	CDocument::StackIncrementedChangeCount( inStack );
	if( mCanvasWindowController )
		[mCanvasWindowController reloadData];
}


void	CDocumentMac::LayerIncrementedChangeCount( CLayer* inLayer )
{
	CDocument::LayerIncrementedChangeCount( inLayer );
	if( mCanvasWindowController )
		[mCanvasWindowController reloadData];
}


std::string	CDocumentMac::GetUserName()
{
	return [NSFullUserName() UTF8String];
}


WILDNSImagePtr	CDocumentMac::GetDisplayIcon()
{
	return [NSImage imageNamed: @"StackCanvasIcon"];
}


Class	CDocumentMac::GetPropertyEditorClass()
{
	return [WILDConcreteObjectInfoViewController class];
}


WILDNSMutableArrayPtr	CDocumentMac::GetMacMenus()
{
	if( !mMacMenus )
		mMacMenus = [[NSMutableArray alloc] init];
	return mMacMenus;
}
