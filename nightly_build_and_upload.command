#! /bin/bash
cd `dirname $0`
REPO_DIR=`pwd`
cd ${REPO_DIR}
BUILD_NUMBER=`git rev-list HEAD | /usr/bin/wc -l | tr -d ' '`
cd ${REPO_DIR}/Stacksmith
touch Stacksmith-Info.plist
cd ${REPO_DIR}/../
BUILD_DEST_PATH=`pwd`/Output/
SIGN_SCRIPT=${REPO_DIR}/Sparkle/bin/sign_update
##security unlock-keychain -p 'password' ~/Library/Keychains/login.keychain
##xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
##  GCC_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  INFOPLIST_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  CODE_SIGN_IDENTITY="Developer ID Application: Your Name" \
##  -configuration Release \
##  clean build
PASSWORD=`security 2>&1 >/dev/null find-internet-password -ga jnknsuliwitness | cut -f2 -d'"'`
mkdir ${BUILD_DEST_PATH}
rm -rf ${BUILD_DEST_PATH}/*
cd ${REPO_DIR}/Stacksmith/
xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
  WILD_DEFINES_FROM_XCODEBUILD="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  WILD_INFO_PLIST_DEFINES_FROM_XCODEBUILD="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  -configuration Release \
  clean build || exit 1
cd ${BUILD_DEST_PATH}
echo "$(tput setaf 6)$(tput bold)===== Compressing Build Product =====$(tput sgr0)"
echo "File: $BUILD_DEST_PATH/Stacksmith.tgz"
tar -czf Stacksmith.tgz Stacksmith.app
echo "$(tput setaf 6)$(tput bold)===== Generating RSS Feed =====$(tput sgr0)"
cd ${REPO_DIR}
${REPO_DIR}/writerss.php ${BUILD_DEST_PATH}/Stacksmith.app/Contents/Info.plist nightly ${BUILD_DEST_PATH}/Stacksmith.tgz `${SIGN_SCRIPT} ${BUILD_DEST_PATH}/Stacksmith.tgz "/Volumes/Confidential/Sparkle Keys/stacksmith_private_sparkle_dsa_key.pem"`
cd ${BUILD_DEST_PATH}
mv nightly_feed.rss stacksmith_nightlies.rss
echo "$(tput setaf 6)$(tput bold)===== Uploading =====$(tput sgr0)"
ftp -in -u "ftp://jnknsuliwitness:${PASSWORD}@stacksmith.org/stacksmith.org/nightlies/" Stacksmith.tgz
ftp -in -u "ftp://jnknsuliwitness:${PASSWORD}@stacksmith.org/stacksmith.org/nightlies/" stacksmith_nightlies.rss