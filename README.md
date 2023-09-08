# docker_Infinity-For-Reddit_builder

Create a custom Infinity-For-Reddit client, using your own Reddit API key.

## Usage

```bash
# clone repo
git clone https://github.com/casperklein/docker_Infinity-For-Reddit_builder infinity-builder
cd infinity-builder

# configure appname, apikey etc.
cp config.example config
vi config

# build APK and save it to ./apk
./build.sh
```

## Update

Make sure to keep the generated `apk/infinity.jks` file from the first build, when creating a new version. Otherwise all user-data gets lost, when installing the new APK.

```bash
./build.sh
```
