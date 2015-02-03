//
//  CObjectID.h
//  Stacksmith
//
//  Created by Uli Kusterer on 05.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

namespace Carlson {

/*!
	Unique ID type that we use to identify all sorts of objects.
	Note that these IDs are only unique among their type of object,
	so you can get the same object ID for a cursor, card and icon.
*/
typedef long long	ObjectID;

}
