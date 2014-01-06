//
//  CMessageBox.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CMessageBox.h"


using namespace Carlson;


CMessageBox*	CMessageBox::GetSharedInstance()
{
	static CMessageBox*		sMessageBox = NULL;
	if( !sMessageBox )
		sMessageBox = new CMessageBox;
	return sMessageBox;
}


bool	CMessageBox::GetTextContents( std::string& outString )
{
	outString = mScript;
	
	return true;
}


bool	CMessageBox::SetTextContents( std::string inString )
{
	mScript = inString;
	
	printf( "%s\n", mScript.c_str() );
	
	return true;
}
