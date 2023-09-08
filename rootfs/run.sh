#!/bin/bash

set -e

if [ -f /apk/infinity.jks ]; then
	echo "Info: Existing keystore found."
	cp -v /apk/infinity.jks /
else
	echo "Info: Using new keystore."
fi
echo

echo "Info: Starting APK build process.."
echo
./gradlew assembleRelease

# Get version
VERSION=$(grep -oP '(?<=versionName ").*(?=")' app/build.gradle)
VERSION_CODE=$(grep -oP '(?<=versionCode ).*' app/build.gradle)

# Copy APK and keystore to /apk
cp -v /Infinity-For-Reddit/app/build/outputs/apk/release/app-release.apk "/apk/${APPNAME}_${VERSION}_$VERSION_CODE.apk"
[ ! -f /apk/infinity.jks ] && cp -v /infinity.jks /apk/

exit 0
