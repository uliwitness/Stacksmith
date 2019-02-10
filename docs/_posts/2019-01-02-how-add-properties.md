---
layout: post
title:  "How to Add Properties to Stacksmith"
date:   2019-01-02 11:21:57 +0100
categories: development
---
There are 3 steps involved in adding a new persistent property to an existing object in Stacksmith (usually implemented as an object that is a subclass of `CConcreteObject` or one of its subclasses):

1. Find the CConcreteObject-conforming C++ class that implements the object to which you want to add a property.
2. Define a C++ instance variable on the object to hold the data at runtime. Write a setter for it that calls IncrementChangeCount() to make sure any change to that property gets saved. Find the `LoadPropertiesFromElement()` method and add code to load the property from the file, and add code to write the property back out again to the `SavePropertiesToElement()` method.
3. Add code that makes the property accessible to scripts to `GetPropertyNamed()` and `SetValueForPropertyNamed()`, keying off the (case-insensitive!) property name for scripts. You will also want to add code to log the property's value to `DumpProperties()` as an aid when debugging.