#! /bin/bash
cd `dirname $0`
REPO_DIR=`pwd`
cd ${REPO_DIR}
BUILD_NUMBER=`git rev-list HEAD | /usr/bin/wc -l | tr -d ' '`
cd ${REPO_DIR}/Stacksmith
touch Stacksmith-Info.plist
cd ${REPO_DIR}/../
BUILD_DEST_PATH=`pwd`/Output/
##security unlock-keychain -p 'password' ~/Library/Keychains/login.keychain
##xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
##  GCC_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  INFOPLIST_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  CODE_SIGN_IDENTITY="Developer ID Application: Your Name" \
##  -configuration Release \
##  clean build
PASSWORD=`security 2>&1 >/dev/null find-internet-password -ga jnknsuliwitness | cut -f2 -d'"'`
if [ ! -d "$BUILD_DEST_PATH" ]; then
	mkdir ${BUILD_DEST_PATH}
fi
rm -rf ${BUILD_DEST_PATH}/*
cd ${REPO_DIR}/Stacksmith/
xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
  WILD_DEFINES_FROM_XCODEBUILD="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  WILD_INFO_PLIST_DEFINES_FROM_XCODEBUILD="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  -configuration Release \
  clean build || exit 1
cd ${BUILD_DEST_PATH}
echo "$(tput setaf 6)$(tput bold)===== Compressing Build Product =====$(tput sgr0)"
tar -czf ~/Programming/Output/Stacksmith.tgz Stacksmith.app

open ~/Programming/Output/
echo -ne '\007'