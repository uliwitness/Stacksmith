//
//  CPartRegistration.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CPartRegistration.h"
#include "CButtonPart.h"
#include "CFieldPart.h"
#include "CTimerPart.h"
#include "CMoviePlayerPart.h"
#include "CWebBrowserPart.h"


extern "C" void	CPartRegistrationRegisterAllPartTypes( void )
{
	static bool		sAlreadyDidThisOne = false;
	
	if( !sAlreadyDidThisOne )
	{
		Carlson::CPart::RegisterPartCreator( "button", new Carlson::CPartCreator<Carlson::CButtonPart>() );
		Carlson::CPart::RegisterPartCreator( "field", new Carlson::CPartCreator<Carlson::CFieldPart>() );
		Carlson::CPart::RegisterPartCreator( "timer", new Carlson::CPartCreator<Carlson::CTimerPart>() );
		Carlson::CPart::RegisterPartCreator( "moviePlayer", new Carlson::CPartCreator<Carlson::CMoviePlayerPart>() );
		Carlson::CPart::RegisterPartCreator( "browser", new Carlson::CPartCreator<Carlson::CWebBrowserPart>() );
		
		sAlreadyDidThisOne = true;
	}
}