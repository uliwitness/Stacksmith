#!/bin/bash

XCODE=`xcode-select --print-path 2> /dev/null`
if [ $? -ne 0 ]; then
	XCODE=/Applications/Xcode.app/Contents/Developer
fi
HEADERDOC2HTML="$XCODE/usr/bin/headerdoc2html"
GATHERHEADERDOC="$XCODE/usr/bin/gatherheaderdoc"

cd `dirname "$0"`/Stacksmith/
rm -rf ../docs/*
$HEADERDOC2HTML -o ../docs .
$GATHERHEADERDOC ../docs