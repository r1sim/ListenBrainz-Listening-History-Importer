‼️ This is no longer needed. You can now import your spotify listens directly on ListenBrainz: https://github.com/metabrainz/listenbrainz-server/releases/tag/v-2025-08-30.0

# ListenBrainz Listening History Importer

This repository contains scripts to import your listening history from streaming services into ListenBrainz. Currently, only Spotify is supported. The scripts are only for historical data. You won't be able to scrobble in real-time using these scripts.


## Usage

This is a cli tool. Using it requires you to be comfortable with the command line. Besides that, the only dependencies are `jq` and `curl` v7.76 or newer. 

### 1. Requesting your listening history  

Since Spotify doesn't provide an API to access your complete listening history, you need to request a copy of your personal data from them. It usually takes a few days for them to provide the data.

**Spotify:**  

1. Go to your [Spotify Privacy Settings](https://www.spotify.com/us/account/privacy/)
2. Request your "Extended Streaming History"
3. Wait for them to send you an email with a download link
4. Download the data and unzip it

### 2. Mapping the data

The data provided by the streaming services is in a format that ListenBrainz doesn't understand. This step will convert the data into a format that ListenBrainz API can understand. No requests are made to ListenBrainz API in this step.

**Spotify:**

```bash
./map_spotify_data.sh -d ~/Downloads/Spotify\ Extended\ Streaming\ History
```

### 3. Submitting the data to ListenBrainz

This step requires a ListenBrainz API token. You can get one yours by going to your [ListenBrainz settings](https://listenbrainz.org/settings/). 

You can then use the `submit_payloads.sh` script to submit the data to ListenBrainz. The script will upload the generated payloads generated in the previous step to ListenBrainz API.

To avoid rate limiting, the script will wait 5 seconds between each request. If you still hit the rate limit, you can just wait a few minutes and run the script again. It will won't re-upload the payloads that were already uploaded.

```bash
./submit_payloads.sh -d ./payloads/spotify -t <YOUR_LISTENBRAINZ_TOKEN>
```

Please be a little patient if you have a lot of data. It might take a while for ListenBrainz to process everything.

## Disclaimer

This project is not affiliated with ListenBrainz, MetaBrainz Foundation or any streaming service. It's a personal project and it's provided as-is. Use it at your own risk.
