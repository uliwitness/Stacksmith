//
//  CMessageBox.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMessageBox__
#define __Stacksmith__CMessageBox__

#include "CScriptableObjectValue.h"


namespace Carlson {


class CMessageBox : public CScriptableObject
{
public:
	static CMessageBox*	GetSharedInstance();

	virtual bool	GetTextContents( std::string& outString );
	virtual bool	SetTextContents( std::string inString);
	
protected:
	std::string		mScript;
};


}

#endif /* defined(__Stacksmith__CMessageBox__) */
