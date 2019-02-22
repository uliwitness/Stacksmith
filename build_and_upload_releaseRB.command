#!/usr/bin/ruby

REPO_DIR = File.dirname(__FILE__)

require 'json'
require 'uri'
require 'net/http'

#system("\""#{ REPO_DIR }/nightly_build.command\""")

puts "===== Creating Release ====="

OWNER = "uliwitness"
REPO = "Stacksmith"
PRODUCT_NAME = "Stacksmith"
TOKEN_KEYCHAIN_ENTRY_NAME = "GithubStacksmithUploadToken"


TOKEN = `security 2>&1 >/dev/null find-generic-password -ga \"#{TOKEN_KEYCHAIN_ENTRY_NAME}\"`.scan(/password: \"(.*)\"/).last.first
BUILD_DEST_PATH = REPO_DIR + "/../Output/"
ARCHIVE_PATH = BUILD_DEST_PATH + "/" + PRODUCT_NAME +  ".tgz"
RSS_PATH = REPO_DIR + "/docs/nightlies/" + PRODUCT_NAME.downcase + "_nightlies.rss"
INFO_PLIST_PATH = BUILD_DEST_PATH + "/" + PRODUCT_NAME + ".app/Contents/Info.plist"

# We assume the version is a valid Mac-style version with dots, maybe a build number
# in brackets, and maybe an prerelease-version character + number ("1.0a11" or
# "1.5.1 (2020)"). Anything else will probably not produce a valid tag.
VERSION = `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "#{INFO_PLIST_PATH}"`
VERSION_TAG = "v" + VERSION.gsub("(", "_").gsub(")", "_").gsub(" ", "_").gsub("__", "_").gsub(/^_+|\_+$/, '')
IS_PRERELEASE = (VERSION_TAG.include? "a" or VERSION_TAG.include? "b")

DESCRIPTION = `xmllint --xpath '//channel/item/description/text()' "#{RSS_PATH}" | textutil -format html -convert txt -stdin -stdout`.gsub("<h3>", "### ").gsub("</h3>", "<br />").gsub("<ul>", "").gsub("</ul>", "").gsub("<li>", " * ").gsub("</li>", "<br />")

TEXT_DESCRIPTION = IO.popen("textutil -format html -convert txt -stdin -stdout", mode="r+") { |io|
  io.write(DESCRIPTION)
  io.close_write
  result = io.read
}

RELEASE = { :tag_name => VERSION_TAG, :target_commitish => "master", :name => (PRODUCT_NAME + " " + VERSION), :body => TEXT_DESCRIPTION, :draft => false, :prerelease => IS_PRERELEASE }.to_json

uri = URI.parse("https://api.github.com/repos/#{OWNER}/#{REPO}/releases")
https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
request = Net::HTTP::Post.new(uri.path, "Authorization" => "token #{TOKEN}")
request.body = RELEASE
response = https.request(request)

puts uri
puts request
puts response
puts VERSION_TAG

#puts TOKEN
#puts DESCRIPTION
#puts IS_PRERELEASE
#puts VERSION_TAG
#puts VERSION
#puts TEXT_DESCRIPTION
#puts RELEASE