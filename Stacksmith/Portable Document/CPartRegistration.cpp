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
		Calhoun::CPart::RegisterPartCreator( "button", new Calhoun::CPartCreator<Calhoun::CButtonPart>() );
		Calhoun::CPart::RegisterPartCreator( "field", new Calhoun::CPartCreator<Calhoun::CFieldPart>() );
		Calhoun::CPart::RegisterPartCreator( "timer", new Calhoun::CPartCreator<Calhoun::CTimerPart>() );
		Calhoun::CPart::RegisterPartCreator( "moviePlayer", new Calhoun::CPartCreator<Calhoun::CMoviePlayerPart>() );
		Calhoun::CPart::RegisterPartCreator( "browser", new Calhoun::CPartCreator<Calhoun::CWebBrowserPart>() );
		
		sAlreadyDidThisOne = true;
	}
}