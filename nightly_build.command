#!/bin/bash
echo "$(tput setaf 6)$(tput bold)===== Starting Build =====$(tput sgr0)"
cd `dirname $0`
REPO_DIR=`pwd`
SIGFILEPATH="/Volumes/Confidential/Sparkle Keys/stacksmith_private_sparkle_dsa_key.pem"
if [ ! -f "$SIGFILEPATH" ]; then
	echo "$(tput setaf 1)$(tput bold)Please make sure the signature file is at $SIGFILEPATH$(tput sgr0)"
	exit 1
fi
cd ${REPO_DIR}
BUILD_NUMBER=`git rev-list HEAD | /usr/bin/wc -l | tr -d ' '`
cd ${REPO_DIR}/Stacksmith
touch Stacksmith-Info.plist
cd ${REPO_DIR}/../
BUILD_DEST_PATH=`pwd`/Output/
SIGN_SCRIPT=${REPO_DIR}/Sparkle/bin/old_dsa_scripts/sign_update
echo "$(tput setaf 6)$(tput bold)===== BUILD! =====$(tput sgr0)"
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

echo "$(tput setaf 6)$(tput bold)===== Generating RSS Feed =====$(tput sgr0)"
DSASIGNATURE=`${SIGN_SCRIPT} "${BUILD_DEST_PATH}/Stacksmith.tgz" "${SIGFILEPATH}"`;
echo "Signature of ${SIGFILEPATH}: $DSASIGNATURE"
cd ${REPO_DIR}
${REPO_DIR}/writerss.php ${BUILD_DEST_PATH}/Stacksmith.app/Contents/Info.plist nightly ${BUILD_DEST_PATH}/Stacksmith.tgz $DSASIGNATURE
cd ${BUILD_DEST_PATH}
mv -f nightly_feed.rss ${REPO_DIR}/docs/nightlies/stacksmith_nightlies.rss

open "${REPO_DIR}/../Output/"
echo -ne '\007'
