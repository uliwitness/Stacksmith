---
layout: post
title:  "How to add new types of Parts to Stacksmith"
date:   2019-01-05 11:21:57 +0100
categories: development
---
It is probably easiest to just take an existing part type and duplicate and rename all its classes. I recommend using "button" or "timer".

Every part needs to have a unique one-word "type" string that can be used for its part type in the XML and for distinguishing it from other part types when listing and accessing parts via other object descriptors than just "part". So pick one now. For example, buttons have "button" and movie players have "moviePlayer".

When should I add a new part vs. a new style of an existing part
----------------------------------------------------------------

Stacksmith and HyperCard before it have a long history of subsuming what would be distinct control types as styles of one part. The main criterion applied here should be what it feels like to the user. Implementation under the hood should not dictate breaking out a new kind of button into something else than a button style. But conversely, just because some objects behave like re-painted versions of each other should not mean they should be the same part type. A good example of this are sliders and scroll bars, which are used for completely different things, so should be different part *types*, not just styles of the same scale part.

A good indicator of a part that should be broken out is often if it suddenly needs to add properties to a part type that have nothing to do with the other part styles. Like the minValue/maxValue properties on SuperCard's scrollbar button style, that none of the others would need. A good example of integrating a completely different control as a style are simple list fields. Users think of these as lists, and write lists into text fields, then think they might want to be able to select a line, so turn on autoSelect and implicitly get a platform-native table view. However, it's also an edge case, as multi-column table views exceed this metaphor and might call for a different implementation.

Registering instructions for a part type
----------------------------------------

All object descriptor syntax is defined by host function tables in `WILDHostFunctions.cpp`. First, add new enum entries to `WILDHostFunctions.h`. You'll usually need 4 instructions: `WILD_CARD_typename_INSTRUCTION`, `WILD_BACKGROUND_typename_INSTRUCTION`, `WILD_NUMBER_OF_CARD_typenameS_INSTRUCTION` and `WILD_NUMBER_OF_BACKGROUND_typenameS_INSTRUCTION`. These let a script enumerate and access your objects on the card and background layers.

Next define the corresponding functions (and their prototypes) in `WILDHostFunctions.cpp`. They are just a small shim that calls through to an internal function that does all the actual work and takes the type string as their parameter. E.g. `WILD_CARD_FIELD_INSTRUCTION` is implemented as:

	void	WILDCardFieldInstruction( LEOContext* inContext )
	{
		WILDCardPartInstructionInternal( inContext, "field" );
	}

There are corresponding `WILDBackgroundPartInstructionInternal`, `WILDNumberOfCardPartsInstructionInternal` and , `WILDNumberOfBackgroundPartsInstructionInternal` functions that you can use to implement the other three instructions.

Now that you have the instruction functions, register them with the instruction table lower in the file by adding `LEOINSTR()` entries for them in between the `LEOINSTR_START()` and `LEOINSTR_LAST()` macros. Note that they must be in the same order as in the header's enum. If your instruction was added at the end of the list, ensure that you change the previous last item into a regular `LEOINSTR()` and make your last item the new `LEOINSTR_LAST()`.

Registering syntax for a part type
----------------------------------

Once you have defined the instruction functions and the symbolic constants you'll refer to them with, you need to define the actual Hammer syntax that scripters will use to refer to your part. A typical object descriptor looks like `card button "foo"` or `background field id 1`. Some may also use several words like `background movie player "double feature"`. In addition, a part may be specified in relation to its containing object, like `card timer 7 of card "timekeepers"`.

#Registering new identifiers

First, you must make sure that any new identifiers you need are defined in `ForgeTypes.h` in the `IDENTIFIERS` macro (most identifiers like `card`, `of` and the like are already defined, so usually all you need to add is the identifiers for the singular and plural form of your object.

To just define a single identifier, say "frog", use

	X1(EFrogIdentifier,"frog")

Where the first parameter is the constant that will be used by you in host code (the "token identifier type"). The second parameter is the actual string the user will use in a Hammer script. This string must be all lower-case. Some older xTalks permitted short forms for identifiers as synonyms that can be typed more quickly. It is generally not recommended to add short forms (users read scripts more often than they write, so they should rather use autocompletion to write the longer identifiers than write a short form that they have to mentally expand when reading every time), but should you need to, you can define a synonym using the `X2` macro:

	X2(EFrgIdentifier,EFrogIdentifier,"frg")

This declares a new token `EFrgIdentifier` that is equal to the string "frg". When the tokenizer generates the token list for parsing, all `EFrgIdentifier` tokens will automatically be changed into `EFrogIdentifier` tokens.

Note that **this is not a general synonym specification mechanism**. Tokens declared as synonymous like this will not be converted back into their short form by the parser. There is no way you can match EFrgIdentifier alone in some spots once it is a synonym for another token. It is recommended to define other synonyms simply by providing two kinds of syntax. This mechanism is simply there to support classic HyperTalk synonyms like `card`/`cd` etc.

#Registering the actual syntax

The actual syntax for an object descriptor is defined in `WILDHostFunctions.cpp` in the `gStacksmithHostFunctions` array. The entries in this table are checked in order. It is recommended you group entries that start with the same identifier together and put the ones that have the most identifiers before the first parameter above the ones that have fewer or an expression right after the first identifier. The Forge parser can currently only backtrack over identifiers, which means that if it parses the object descriptor `card button "foo"` encounters the syntax entry for `card "foo"` *first* it can not backtrack once it has matched `button` as a variable name, and will thus present a syntax error before it ever gets to the case for `card button "foo"`.

There are six entries for each part type's syntax: "card *typename* x", "background *typename* x", "number of card *typename*s", "number of background *typename*s" and the shorter "*typename* x" equivalent to "card *typename* x", and "number of *typename*s" equivalent to "number of card *typename*s". Just duplicate the entries and the array will resize to accomodate them.

Creating the actual class that implements a part
------------------------------------------------

There are generally two classes. The cross-platform class, e.g. `CButtonPart`, and a platform-specific subclass that actually implements a part's physical appearance in platform-native API. On the Mac, that would be `CButtonPartMac`, which is a subclass of both `CButtonPart` and `CMacPartBase`, which implements some common behaviours and API specific to the Mac.

`CButtonPart` uses tinyxml2 API to load and save itself from disk, and defines properties to hold this information and the code to allow scripts to access its attributes.

`CButtonPartMac` defines the `CreateViewIn()` and `DestroyView()` methods that the subclass should override to (re)create a Macintosh `NSView` or dispose of it and remove it from display. In addition, it implements methods like `GetPropertyEditorClass()` and `GetDisplayIcon()` that return Mac stuff specific to this object that the UI needs to properly display the various editors. It also implements some convenience methods that convert certain typical Stacksmith internal data types into Mac types and back, and that provide canned implementations of typical Mac implementations for cross-platform methods, like `CMacPartBase::OpenScriptEditorAndShowOffset()`, which you should call from your subclass's `CPart::OpenScriptEditorAndShowOffset()` override to make sure scripts can ask your part to show its script editor and it will show a Mac window containing the script editor.

Once you have the class, you have to make the platform-specific `CStack` subclass aware that it should use this subclass when it encounters a part of your type. On the Mac, you add a line like this to `CStackMac`'s `RegisterPartCreators()` static method:

	CPart::RegisterPartCreator( new CPartCreator<CButtonPartMac>( "button" ) );

Where "button" here is the unique type string you picked for your part type.

Adding UI for creating your part
--------------------------------

Currently, there is no standard mechanism for creating new parts. You'll have to duplicate the CStackMac's `-newButton:` method rename and change it to create your part type, and create a menu item for it in the MainMenu.xib and hook it up to the `-newButton:` action on *First Responder*, and make sure your part can cope with being created without having been given any XML to load. Hopefully we can eventually use XML templates so your part can get a sensible default size and default attributes from there, and we can generate the "New X" menu items automatically.
