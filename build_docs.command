#!/bin/bash

XCODE=`xcode-select --print-path 2> /dev/null`
if [ $? -ne 0 ]; then
	XCODE=/Applications/Xcode.app/Contents/Developer
fi
HEADERDOC2HTML="$XCODE/usr/bin/headerdoc2html"
GATHERHEADERDOC="$XCODE/usr/bin/gatherheaderdoc"

cd `dirname "$0"`
rm -rf `dirname "$0"`/docs/apidocs/*
$HEADERDOC2HTML -o `dirname "$0"`/docs/apidocs `dirname "$0"`/Stacksmith/
$HEADERDOC2HTML -o `dirname "$0"`/docs/apidocs `dirname "$0"`/Forge/
$GATHERHEADERDOC `dirname "$0"`/docs/apidocs
