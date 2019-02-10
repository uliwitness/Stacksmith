---
layout: post
title:  "How to add functions to Stacksmith"
date:   2019-01-03 11:21:57 +0100
categories: development
---
There are three ways to implement functions in Stacksmith:

1. Built-in functions - These look and are called like any function handler implemented in Hammer, but actually compile to an instruction you define. However, they are limited to taking no parameters, and you can currently only add one by directly editing the built-in function table in <tt>CParser.cpp</tt>.

2. Host functions - These follow fairly freeform syntax, and are defined like host commands, using a table you pass to <tt>LEOAddHostFunctionsAndOffsetInstructions</tt>, and compile to an instruction as well. The return value of the function must be pushed on the stack by your instruction after all parameters have been removed.

3. Provide a <tt>callNonexistentHandlerProc</tt> to the LEOContext and at that point handle any function for which no handler exists in the current message path. The number of parameters and the parameters themselves will have been pushed on the stack, and can be accessed using the utility function <tt>LEOGetParameterAtIndexFromEndOfStack</tt>. Once you are done, use the utility function <tt>LEOCleanUpHandlerParametersFromEndOfStack</tt> to remove your parameters from the stack.

See [How to add commands to Stacksmith](2019-01-04-how-to-add-commands) on how to create your own instructions, and how the general process of specifying a syntax table work in Stacksmith.

