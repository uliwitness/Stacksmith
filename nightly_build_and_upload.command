#! /bin/bash
cd `dirname $0`
REPO_DIR=`pwd`
cd ${REPO_DIR}
BUILD_NUMBER=`git rev-list HEAD | /usr/bin/wc -l | tr -d ' '`
cd ${REPO_DIR}/Stacksmith
touch Stacksmith-Info.plist
cd ${REPO_DIR}/../
BUILD_DEST_PATH=`pwd`/Output/
mkdir ${BUILD_DEST_PATH}
rm -rf ${BUILD_DEST_PATH}/*
##security unlock-keychain -p 'password' ~/Library/Keychains/login.keychain
##xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
##  GCC_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  INFOPLIST_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
##  CODE_SIGN_IDENTITY="Developer ID Application: Your Name" \
##  -configuration Release \
##  clean build
cd ${REPO_DIR}/Stacksmith/
xcodebuild CONFIGURATION_BUILD_DIR=$BUILD_DEST_PATH \
  GCC_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  INFOPLIST_PREPROCESSOR_DEFINITIONS="SVN_VERSION_NUM=${BUILD_NUMBER} SVN_BUILD_MEANS=nightly" \
  -configuration Release \
  clean build
cd ${BUILD_DEST_PATH}
tar -czf Stacksmith.tgz Stacksmith.app
PASSWORD=`security 2>&1 >/dev/null find-internet-password -ga jnknsuliwitness | cut -f2 -d'"'`
cd ${REPO_DIR}
${REPO_DIR}/writerss.php ${BUILD_DEST_PATH}/Stacksmith.app/Contents/Info.plist nightly ${BUILD_DEST_PATH}/Stacksmith.tgz
cd ${BUILD_DEST_PATH}
mv nightly_feed.rss stacksmith_nightlies.rss
ftp -in -u "ftp://jnknsuliwitness:${PASSWORD}@stacksmith.org/stacksmith.org/nightlies/" Stacksmith.tgz
ftp -in -u "ftp://jnknsuliwitness:${PASSWORD}@stacksmith.org/stacksmith.org/nightlies/" stacksmith_nightlies.rss