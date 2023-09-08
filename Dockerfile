# Heavily inspired from: https://www.reddit.com/r/Infinity_For_Reddit/comments/14c2v5x/build_your_own_apk_with_your_personal_api_key_in/

FROM	debian:11-slim as base

ARG	GITHUB_USER="Docile-Alligator"
ARG	GITHUB_REPO="Infinity-For-Reddit"
ARG	GITHUB_COMMIT="v6.1.1"
ARG	GITHUB_ARCHIVE="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/$GITHUB_COMMIT.tar.gz"

ARG	API_APP_NAME
ARG	API_APP_VERSION
ARG	API_USER
ENV	USER_AGENT="android:$API_APP_NAME:$API_APP_VERSION (by /u/$API_USER)"
ARG	API_KEY

ARG	APPNAME
# used in run.sh
ENV	APPNAME="$APPNAME"
ARG	PACKAGENAME

ENV	ANDROID_SDK_ROOT="/android-sdk"
ENV	PATH="$PATH:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools"

# ENV	JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
# ENV	JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# check if build-arguments are given
RUN     [ -z "$API_APP_NAME" ] && echo "Error: Build argument 'API_APP_NAME' is missing" && exit 1 || true
RUN     [ -z "$API_APP_VERSION" ] && echo "Error: Build argument 'API_APP_VERSION' is missing" && exit 1 || true
RUN     [ -z "$API_KEY" ] && echo "Error: Build argument 'API_KEY' is missing" && exit 1 || true
RUN     [ -z "$API_USER" ] && echo "Error: Build argument 'API_USER' is missing" && exit 1 || true
RUN     [ -z "$APPNAME" ] && echo "Error: Build argument 'APPNAME' is missing" && exit 1 || true
RUN     [ -z "$PACKAGENAME" ] && echo "Error: Build argument 'PACKAGENAME' is missing" && exit 1 || true

SHELL	["/bin/bash", "-c"]

ARG	PACKAGES="coreutils openjdk-11-jdk patch unzip wget"
# ARG	PACKAGES="coreutils openjdk-17-jdk patch unzip wget" # debian 12 --> does not build

ARG	DEBIAN_FRONTEND=noninteractive
RUN	apt-get update \
&&	apt-get -y upgrade \
&&	apt-get -y --no-install-recommends install $PACKAGES \
&&	rm -rf /var/lib/apt/lists/*

# Get SDK #########################################################################################
FROM	base as sdk

# https://developer.android.com/studio (scroll down to "Command line tools only" to get the latest version)
ENV	SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
RUN	wget -O android-sdk.zip $SDK_URL \
&&	unzip -q android-sdk.zip -d android-sdk

RUN	yes | $ANDROID_SDK_ROOT/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platforms;android-30" "build-tools;30.0.3"

# Prepare build ##################################################################################
FROM	base

# Get sed wrapper
RUN	wget -O /bin/sedfile https://raw.githubusercontent.com/casperklein/bash-pack/master/sedfile \
&&	chmod 700 /bin/sedfile

# Get source
WORKDIR	/$GITHUB_REPO
RUN	wget -O - "$GITHUB_ARCHIVE" | tar --strip-component 1 -xzv

# Change API token, redirect URI and user-agent
ENV	APIUTILS_FILE="/Infinity-For-Reddit/app/src/main/java/ml/docilealligator/infinityforreddit/utils/APIUtils.java"
ENV	API_KEY_OLD="NOe2iKrPPzwscA"
RUN	sedfile -i -E 's/(public static final String CLIENT_ID = ")'"$API_KEY_OLD"'";/\1'"$API_KEY"'";/g' "$APIUTILS_FILE" \
&&	grep '^\s*public static final String CLIENT_ID = "'"$API_KEY"'";$' "$APIUTILS_FILE"

RUN	sedfile -i 's|infinity://localhost|http://127.0.0.1|' "$APIUTILS_FILE"
RUN	sedfile -i 's|public static final String USER_AGENT =.*|public static final String USER_AGENT = "'"$USER_AGENT"'";|' "$APIUTILS_FILE"

# Change package name
RUN	grep -lRF ml.docilealligator.infinityforreddit | xargs -l sedfile -i 's|ml.docilealligator.infinityforreddit|'"$PACKAGENAME"'|g'

# Change app name
RUN	sedfile -i 's|se">Infinity<|se">'"$APPNAME"'<|'  app/src/main/res/values/strings.xml # APPLICATION_NAME
RUN	sedfile -i 's|el">Infinity<|el">'"$APPNAME"'<|' app/src/main/res/values/strings.xml  # APPLICATION_LABEL

# Create keystore
# TODO  https://stackoverflow.com/a/13578480/568737
RUN	yes | keytool -genkey -keyalg RSA -alias Infinity -keystore /infinity.jks -keypass Infinity -storepass Infinity

# Use keystore
COPY	rootfs/build.gradle.patch .
RUN	patch -i build.gradle.patch app/build.gradle

# build APK
COPY	--from=sdk $ANDROID_SDK_ROOT $ANDROID_SDK_ROOT

COPY	rootfs/run.sh /
CMD	["/run.sh"]
