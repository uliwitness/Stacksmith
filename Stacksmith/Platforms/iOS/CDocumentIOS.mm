//
//  CDocumentIOS.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-20.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#include "CDocumentIOS.h"
#include "CAlert.h"
#include <sstream>
#include "CCompletionBlockCoalescer.h"
#import "UKHelperMacros.h"
#import <Foundation/Foundation.h>


using namespace Carlson;


void	CDocumentManagerIOS::OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup, TOpenInvisibly openInvisibly )
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
        mOpenDocuments.push_back( new CDocumentIOS(inGroup) );
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
								inCard->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [inDocument,completionBlockObj,inURL,inEffectType,inSpeed](){ completionBlockObj->Success(inDocument); }, inEffectType, inSpeed );
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


void	CDocumentManagerIOS::Quit()
{
	exit(0);	// TODO: Implement for iOS.
}

