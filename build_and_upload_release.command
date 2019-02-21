#!/bin/bash

source "`dirname $0`/nightly_build.command"

OWNER="uliwitness"
REPO="Stacksmith"
TOKEN=`security 2>&1 >/dev/null find-generic-password -ga GithubStacksmithUploadToken | cut -f2 -d'"'`

cd `dirname $0`
REPO_DIR=`pwd`
cd ${REPO_DIR}/../
BUILD_DEST_PATH=`pwd`/Output/
ARCHIVE_PATH="$BUILD_DEST_PATH/Stacksmith.tgz"
RSS_PATH="$BUILD_DEST_PATH/stacksmith_nightlies.rss"
INFO_PLIST_PATH="${BUILD_DEST_PATH}/Stacksmith.app/Contents/Info.plist"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST_PATH")
VERSION_TAG="${VERSION// /_}"
VERSION_TAG="${VERSION_TAG//(/_}"
VERSION_TAG="${VERSION_TAG//)/_}"
VERSION_TAG="${VERSION_TAG//__/_}"
VERSION_TAG=$"$(echo -e "${VERSION_TAG}" | sed -e 's/[[_]]*$//')"

if [[ $VERSION_TAG == *"a"* || $VERSION_TAG == *"b"* ]]; then
	IS_PRERELEASE="true"
else
	IS_PRERELEASE="false"
fi

DESCRIPTION=$(xmllint --xpath '//channel/item/description/text()' "$RSS_PATH" | textutil -format html -convert txt -stdin -stdout | textutil -format html -convert txt -stdin -stdout)
DESCRIPTION="${DESCRIPTION//\"/\\\"}"
DESCRIPTION=$(echo -e "$DESCRIPTION" | sed -e :a -e '$!N;s/\n/\\n/;ta')

#echo $VERSION_TAG
#echo "$DESCRIPTION"
#echo $ARCHIVE_PATH
#echo $TOKEN
#exit 1

## Make a draft release json with a markdown body
release='"tag_name": "v'"$VERSION_TAG"'", "target_commitish": "master", "name": "Stacksmith '"$VERSION"'", '
body=\"$DESCRIPTION\"
body='"body": '$body', '
release=$release$body
release=$release'"draft": false, "prerelease": '"$IS_PRERELEASE"
release='{'$release'}'
url="https://api.github.com/repos/$OWNER/$REPO/releases"

echo "$release"

succ=$(curl -H "Authorization: token $TOKEN" --data "$release" "$url")

## In case of success, we upload a file
upload=$(echo $succ | grep upload_url)
if [[ $? -eq 0 ]]; then
	echo Release created.
else
	echo Error creating release!
	exit 1
fi

cd "`dirname ${ARCHIVE_PATH}`"
ARCHIVE_NAME="`basename ${ARCHIVE_PATH}`"

# $upload is like:
# "upload_url": "https://uploads.github.com/repos/:owner/:repo/releases/:ID/assets{?name,label}",
upload=$(echo "$upload" | egrep -o "\"upload_url\":[ \t]*\"(.+?)\"," | head -n 1)
upload=$(echo $upload | cut -d "\"" -f4 | cut -d "{" -f1)
upload="$upload?name=${ARCHIVE_NAME}"
echo "Uploading to: $upload"

succ=$(curl -L --post301 --post302 --post303 \
-H "Authorization: token $TOKEN" \
-H "Content-Type: $(file -b --mime-type $ARCHIVE_NAME)" \
-H "Accept: application/vnd.github.v3+json" \
--data-binary @${ARCHIVE_NAME} $upload)

echo "$succ"

download=$(echo $succ | egrep -o "\"url\":[ \t]*\"(.+?)\"," | head -n 1)
if [[ $? -eq 0 ]]; then
	releaseurl="https://github.com/${OWNER}/${REPO}/releases/tag/v${VERSION_TAG}"
	echo "New release at: $releaseurl"
	open -a "Safari" "$releaseurl"
else
	echo Upload error!
	echo "$download"
	exit 2
fi
