//
//  main.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <stdlib.h>


static inline unsigned TimeToUnsigned( time_t inTime ) { return (unsigned)inTime; }	// Typecast that breaks when srand's type ever changes during a port.


int main(int argc, char *argv[])
{
	srand( TimeToUnsigned(time(NULL)) );
	
    return NSApplicationMain(argc, (const char **) argv);
}
