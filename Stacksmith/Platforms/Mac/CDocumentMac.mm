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
#import "WILDStackCanvasWindowController.h"


using namespace Carlson;


CStack*		CDocumentMac::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
{
	return new CStackMac( inURL, inID, inName, inFileName, inDocument );
}


void	CDocumentManagerMac::OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed )
{
    try
    {
        //UKLog(@"Entered");
        
        std::string		fileURL( inURL );
		if( fileURL.length() > 0 && fileURL[fileURL.length() -1] != '/' )
			fileURL.append( 1, '/' );
        fileURL.append("project.xml");
        size_t	foundPos = fileURL.find("x-stack://");
        size_t	foundPos2 = fileURL.find("file://");
        if( foundPos == 0 )
            fileURL.replace(foundPos, 10, "http://");
        else if( foundPos2 == 0 )
        {
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
			if( currDoc->GetURL().compare( slashlessFileURL ) == 0 )
			{
				currDoc->GetStack(0)->GetCard(0)->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [currDoc,inCompletionBlock](){ inCompletionBlock(currDoc); }, inEffectType, inSpeed );
				[NSDocumentController.sharedDocumentController noteNewRecentDocumentURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]];
				return;
			}
		}
		
		// Wasn't already open? Create a new one and load the URL into it:
        mOpenDocuments.push_back( new CDocumentMac() );
        CDocumentRef	currDoc( mOpenDocuments.back(), true );	// Take over ownership of the pointer we just 'new'ed, mOpenDocuments retains it by itself.
        
        currDoc->LoadFromURL( fileURL, [this,inCompletionBlock,inURL,inEffectType,inSpeed](Carlson::CDocument * inDocument)
        {
			NSString*	urlStr = [[[NSBundle mainBundle] bundleURL] absoluteString];
			if( [urlStr characterAtIndex: urlStr.length -1] != '/' )
			{
				urlStr = [urlStr stringByAppendingString: @"/"];	// Make sure it ends in a slash so we don't grab folders next to the app.
			}
			if( inURL.find( [urlStr UTF8String] ) == 0 )	// Built-in stack?
				inDocument->SetWriteProtected(true);
			
            //UKLog(@"Doc completion entered");
            Carlson::CStack		*		theCppStack = inDocument->GetStack( 0 );
            if( !theCppStack )
            {
                UKLog(@"No stacks in project %p", inDocument);
                CloseDocument( inDocument );
				inCompletionBlock(NULL);
                return;
            }
            theCppStack->Load( [this,inDocument,inCompletionBlock,inURL,inEffectType,inSpeed](Carlson::CStack* inStack)
            {
				//UKLog(@"Stack completion entered %p", inStack);
                //inStack->Dump();
				if( !inStack->IsLoaded() )
				{
                    CloseDocument( inDocument );
                    UKLog(@"Error loading stack for document %p", inDocument);
					inCompletionBlock(NULL);
					return;
				}
				CCard	*	firstCard = (inStack ? inStack->GetCard(0) : NULL);
                //UKLog(@"Stack completion entered (2) %p in %p", firstCard, inStack);
                firstCard->Load( [this,inDocument,inStack,inCompletionBlock,inURL,inEffectType,inSpeed](Carlson::CLayer*inCard)
                {
                    //UKLog(@"Card completion entered %p",inCard);
					if( inCard )
					{
                    	inCard->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [inDocument,inCompletionBlock,inURL,inEffectType,inSpeed](){ [NSDocumentController.sharedDocumentController noteNewRecentDocumentURL: [NSURL URLWithString: [NSString stringWithUTF8String: inURL.c_str()]]]; inCompletionBlock(inDocument); }, inEffectType, inSpeed );
					}
					else
					{
                        CloseDocument( inDocument );
						inCompletionBlock(NULL);
					}
                    //UKLog(@"Card completion exited");
                } );
                //UKLog(@"Stack completion exited");
            } );
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
