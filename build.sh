#!/bin/bash

set -e
shopt -s inherit_errexit

BASE=$(dirname "$(readlink -f "$0")")
cd "$BASE"

# Get config
if source config 2>/dev/null; then
	export API_APP_NAME
	export API_APP_VERSION
	export API_KEY
	export API_USER

	export APPNAME
	export PACKAGENAME

	BUILD_ARGS=(
		"--build-arg" "API_APP_NAME"
		"--build-arg" "API_APP_VERSION"
		"--build-arg" "API_KEY"
		"--build-arg" "API_USER"

		"--build-arg" "APPNAME"
		"--build-arg" "PACKAGENAME"
	)
else
	echo "Error: 'config' file not accessible."
	echo
	exit 1
fi >&2

# Create build image
docker build --no-cache -t "${APPNAME,,}-builder" "${BUILD_ARGS[@]}" .
echo

# Build APK
docker run --rm -it -v "$BASE/apk:/apk" "${APPNAME,,}-builder"
echo

echo "APK successfully created."
echo

# Show APK and keystore
hash tree 2>/dev/null && tree "$BASE/apk" && echo
exit 0
