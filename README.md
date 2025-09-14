# docker_Infinity-For-Reddit_builder

Create a custom [Infinity-For-Reddit](https://github.com/Docile-Alligator/Infinity-For-Reddit) client, using your own Reddit API key.

## Create Reddit App And API Key

1. Goto <https://old.reddit.com/prefs/apps/>
2. Create a new app with the following settings:
   * Name: `SomeFunkyAppName`
   * Type: installed app
   * Redirect URI: `http://127.0.0.1`
3. After the app creation, the API token is shown at the bottom of the page under the app name (SomeFunkyAppName) and is a set of random characters (e.g. 6g5ZHEGEAnKHP3vewUFY3y)

## Usage

```bash
# clone repo
git clone https://github.com/casperklein/docker_Infinity-For-Reddit_builder infinity-builder
cd infinity-builder

# configure APPNAME, API_KEY etc.
cp config.example config
vi config

# build APK and save it to ./apk
./build.sh [<commit/tag>]
```

## Update

Make sure to keep the generated `apk/infinity.jks` file from the first build, when creating a new version. Otherwise you won't be able to update your app.

```bash
./build.sh [commit/tag]
```
