#!/bin/bash

cd `dirname "$0"`/Stacksmith/
rm -rf ../docs/*
/Applications/Xcode.app/Contents/Developer/usr/bin/headerdoc2html -o ../docs .
/Applications/Xcode.app/Contents/Developer/usr/bin/gatherheaderdoc ../docs