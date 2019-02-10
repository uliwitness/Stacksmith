#!/bin/bash

# this requires Jekyll, which you can get by running $ sudo gem install jekyll
# create a new site using $ jekyll new my-awesome-site

SERVER="orangejuiceliberationfront.com"
ACCOUNT="uliwitness"
PORT=22
REMOTEPATH=/home/uliwitness/orangejuiceliberationfront.com
PASSWORD=`security find-internet-password -a "$ACCOUNT" -s "$SERVER" -r ftps -w`
SITEPATH="`dirname $0`/_site/"

cd "$SITEPATH.."
jekyll build

# sftp has a bug where it won't create folders, all folders have to exist.
#	so loop over all folders first and create them:
cd "$SITEPATH"
FOLDERS=`find . -type d`
MAKEFOLDERSCRIPT=""
while read -r line; do
	if [ "$line" != "." ]; then
    	MAKEFOLDERSCRIPT+=$'expect "sftp>"\n'
    	MAKEFOLDERSCRIPT+=$'send "mkdir '
    	MAKEFOLDERSCRIPT+="$line"
    	MAKEFOLDERSCRIPT+=$'\\n"\n'
    fi
done <<< "$FOLDERS"

FILES=`find . -type f`
UPLOADFILESSCRIPT=""
while read -r line; do
	if [ "$line" != "." ]; then
    	UPLOADFILESSCRIPT+=$'expect "sftp>"\n'
    	UPLOADFILESSCRIPT+=$'send "put '
    	UPLOADFILESSCRIPT+="$line $line"
    	UPLOADFILESSCRIPT+=$'\\n"\n'
    fi
done <<< "$FILES"

echo "Creating folders..."
expect >/dev/null 2>&1 <<END_SCRIPT
spawn sftp -r -P "${PORT}" "${ACCOUNT}@${SERVER}"
expect "password:"
send "${PASSWORD}\n"
expect "sftp>"
send "progress\n"
expect "sftp>"
send "cd ${REMOTEPATH}\n"
${MAKEFOLDERSCRIPT}
expect "sftp>"
send "bye\n"
interact
END_SCRIPT

echo " "
expect<<END_SCRIPT
spawn sftp -r -P "${PORT}" "${ACCOUNT}@${SERVER}"
expect "password:"
send "${PASSWORD}\n"
expect "sftp>"
send "progress\n"
expect "sftp>"
send "cd ${REMOTEPATH}\n"
${UPLOADFILESSCRIPT}
expect "sftp>"
send "bye\n"
interact
END_SCRIPT

