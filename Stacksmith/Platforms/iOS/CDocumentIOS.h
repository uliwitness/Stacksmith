//
//  CDocumentIOS.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-20.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CDocumentIOS__
#define __Stacksmith__CDocumentIOS__

#include "CDocument.h"


namespace Carlson
{

	class CDocumentIOS;


	class CDocumentManagerIOS : public CDocumentManager
	{
	public:
		virtual ~CDocumentManagerIOS()	{}
		
		virtual void	OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup, TOpenInvisibly openInvisibly ) override;
		
		virtual void	Quit() override;
	};


	class CDocumentIOS : public CDocument
	{
	public:
		CDocumentIOS( LEOContextGroup* inGroup ) : CDocument(inGroup) {}
		~CDocumentIOS() {}

		virtual CStack	*	NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) override;
	};

}

#endif /* defined(__Stacksmith__CDocumentIOS__) */
