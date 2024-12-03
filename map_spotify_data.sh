#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [-h] [-d my_spotify_data_dir]"
    echo "  -h  Display help"
    echo "  -d  Path to my_spotify_data dir     (Request extended streaming history on https://www.spotify.com/en/account/privacy/)"
    exit 1
}

while getopts ":h:d:" opt; do
    case ${opt} in
    h)
        usage
        ;;
    d)
        MY_SPOTIFY_DATA_PATH=$OPTARG
        ;;
    \?)
        echo "Invalid option: $OPTARG" 1>&2
        usage
        ;;
    :)
        echo "Invalid option: $OPTARG requires an argument" 1>&2
        usage
        ;;
    esac
done

if [ ! -d "$MY_SPOTIFY_DATA_PATH" ]; then
    echo "Directory \"$MY_SPOTIFY_DATA_PATH\" does not exist."
    usage
fi

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq is not installed. Please install jq (https://jqlang.github.io/jq/download/)"
    exit 1
fi

# Ensure result dir contains no files
ABSOLUTE_SCRIPT_PATH=$(
    cd "$(dirname "$0")"
    pwd
)
PAYLOAD_PATH="$ABSOLUTE_SCRIPT_PATH/payloads/spotify"
mkdir -p "$PAYLOAD_PATH"

if [ -d "$PAYLOAD_PATH" ]; then
    if [ "$(ls -A "$PAYLOAD_PATH")" ]; then
        echo "Directory $PAYLOAD_PATH is not empty."
        exit 1
    fi
fi

for file in "$MY_SPOTIFY_DATA_PATH"/Streaming_History_Audio_*.json; do
    FILENAME=$(basename "$file")
    FILENAME_WITHOUT_EXTENSION=${FILENAME%.json}
    SHORT_FILE_NAME=${FILENAME_WITHOUT_EXTENSION#Streaming_History_Audio}
    echo "Processing $FILENAME_WITHOUT_EXTENSION_AND_PREFIX..."

    # Map data to Listenbrainz format. This will filter out all plays shorter than 1 minute and tracks without a Spotify URI.
    MAPPED_DATA=$(cat "$file" | jq -c '[.[] | select(.ms_played > 60000 and .spotify_track_uri != null) | {
        "listened_at": (.ts | fromdateiso8601),
        "track_metadata": { 
            "artist_name": .master_metadata_album_artist_name, 
            "track_name": .master_metadata_track_name, 
            "release_name": .master_metadata_album_album_name,
            "music_service": "spotify.com", 
            "spotify_id": ("http://open.spotify.com/track/" + (.spotify_track_uri | split(":")[2])) 
        }
    }]')

    # Split mapped data into arrays of 500 elements. We will import 500 listens per request.
    echo "$MAPPED_DATA" | jq -c '. as $in | reduce range(0; (length/500 | ceil)) as $i ([]; . + [$in[($i*500):(($i+1)*500)]])' |
        jq -c '.[]' |
        while read -r chunk; do
            COUNTER=$((COUNTER + 1))
            PAYLOAD_FILE_PATH="$PAYLOAD_PATH/payload${SHORT_FILE_NAME}_$COUNTER.json"
            echo '{"listen_type": "import", "payload": '"$chunk"'}' >"$PAYLOAD_FILE_PATH"
            echo "Generated payload $PAYLOAD_FILE_PATH"
        done
done
