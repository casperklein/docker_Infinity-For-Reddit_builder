#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

checkBinarys() {
        local i
        for i in "$@"; do
                hash "$i" 2>/dev/null || {
                        echo "Binary missing: $i"
                        echo
                        exit 1
                } >&2
        done
}
checkBinarys "curl" "dirname" "docker" "readlink"  #"jq"

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

if [ -z "${1:-}" ]; then
	LATEST=$(curl -sLf https://api.github.com/repos/Docile-Alligator/Infinity-For-Reddit/releases/latest | jq -r '.name' 2>/dev/null || echo "master")
	[ "$LATEST" == "master" ] && echo "Error: Latest version/tag could not be determined."

	read -r -p "Enter the commit/tag you want Infinity-For-Reddit to build from [$LATEST]: " GITHUB_COMMIT
	echo

	[ -z "$GITHUB_COMMIT" ] && GITHUB_COMMIT=$LATEST
else
	GITHUB_COMMIT=$1
fi
export GITHUB_COMMIT
BUILD_ARGS+=("--build-arg" "GITHUB_COMMIT")
echo "Building Infinity-For-Reddit: $GITHUB_COMMIT"
echo

# Create builder image
docker build -t "${APPNAME,,}-builder" "${BUILD_ARGS[@]}" .
echo

# Build APK
docker run --rm -it -v "$BASE/apk:/apk" "${APPNAME,,}-builder"
echo

echo "APK successfully created."
echo

# Show APK and keystore
hash tree 2>/dev/null && tree "$BASE/apk" && echo
exit 0
