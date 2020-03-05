---
layout: page
title: Technical Overview
permalink: /technical-overview/
---

## What is Stacksmith?

Stacksmith is an open source project aiming to create a modern HyperCard. A software erector kit that allows beginners to quickly learn to create their own apps, and that stays flexible and powerful enough that it can be used as a development environment for professionals. The main goal of Stacksmith is to be *humane*, to think like a person does instead of making a person think like a computer.

![The structure of Stacksmith](/assets/StacksmithStructure.svg)

Stacksmith is built from different components, some of which are useful on their own.

There is the ForgeDebugger helper application that is used to debug script execution.

There is the Stacksmith application proper that serves as an IDE and runtime. The Stacksmith application is built from a cross-platform C++ core and a thin layer of classes that provide features that the C++ and C standard libraries do not provide, like downloading files from the web or drawing.

The user interface layer on the Mac is implemented in standard Objective-C and takes advantage of common utility code like the Sparkle software update framework and various custom views to make it a standard Mac application.

Scripts are run by a virtual machine/bytecode interpreter called "Leonie" and compiled to that bytecode by the built-in "Forge" compiler (which can also be used to run HyperTalk scripts separately, like as shell scripts).

So while Stacksmith will feel and run like any other Mac application, it is ready to be ported to other platforms without having to rewrite the entirety of the program.
