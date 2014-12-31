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


using namespace Carlson;


CStack*		CDocumentMac::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
{
	return new CStackMac( inURL, inID, inName, inFileName, inDocument );
}


void	CDocumentManagerMac::OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock )
{
    try
    {
        UKLog(@"Entered");
        
        std::string		fileURL( inURL );
        fileURL.append("/project.xml");
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
                fileURL.append("/toc.xml");	// +++ old betas used toc.xml for the main file.
            }
        }
        
        mOpenDocuments.push_back( new CDocumentMac() );
        CDocumentRef	currDoc = mOpenDocuments.back();
        
        currDoc->LoadFromURL( fileURL, [inCompletionBlock](Carlson::CDocument * inDocument)
        {
            UKLog(@"Doc completion entered");
            Carlson::CStack		*		theCppStack = inDocument->GetStack( 0 );
            if( !theCppStack )
            {
                std::stringstream	errMsg;
                errMsg << "Can't find stack at " << inDocument->GetURL() << ".";
                CAlert::RunMessageAlert( errMsg.str() );
				inCompletionBlock(NULL);
                return;
            }
            theCppStack->Load( [inDocument,inCompletionBlock](Carlson::CStack* inStack)
            {
				UKLog(@"Stack completion entered %p", inStack);
                inStack->Dump();
				if( !inStack->IsLoaded() )
				{
					inCompletionBlock(NULL);
                	UKLog(@"Error loading stack for document %p", inDocument);
					return;
				}
                UKLog(@"Stack completion entered (2) %p", (inStack? inStack->GetCard(0) : NULL));
                inStack->GetCard(0)->Load( [inDocument,inStack,inCompletionBlock](Carlson::CLayer*inCard)
                {
                    UKLog(@"Card completion entered %p",inCard);
					if( inCard )
					{
                    	inCard->GoThereInNewWindow( EOpenInNewWindow, NULL, NULL, [inDocument,inCompletionBlock](){ inCompletionBlock(inDocument); } );
					}
					else
					{
						inCompletionBlock(NULL);
					}
                    UKLog(@"Card completion exited");
                } );
                UKLog(@"Stack completion exited");
            } );
            UKLog(@"Doc completion exited");
        });

        UKLog(@"Exited");
    }
    catch( std::exception& inException )
    {
        UKLog( @"Exception caught: %s", inException.what() );
        return inCompletionBlock(NULL);
    }
    catch( ... )
    {
        UKLog( @"Unknown exception caught" );
        return inCompletionBlock(NULL);
    }
}
