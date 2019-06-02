#!/bin/bash

# play.sh <url> <quality>
# A script for downloading and assembling online video streams.


exit_route () {
    local msg=$1
    echo "$msg"
    exit 1
}

VERBOSITY="--quiet"
VERBOSITY=""
SCRIPT_PATH=.
WGET_PARAMETERS=$(head -n 1 $SCRIPT_PATH/cookies-wget.txt)

tempfile_cmd="mktemp -t playvideo.XXXXX"

cookies=$($tempfile_cmd)
login_result_page=$($tempfile_cmd)


page_url=$1
page_file=$($tempfile_cmd)

echo ">>> Fetching main page: $page_url"
echo "-----------------------------------------"
echo $WGET_PARAMETERS
echo "-----------------------------------------"
wget $VERBOSITY "$WGET_PARAMETERS" \
     --output-document $page_file \
     "$page_url" || exit_route ">> Failed"
echo ">>> Done."

# Fetching subtitle urls
tracks="$(cat $page_file  | sed -n '/tracks:/p' | sed 's/tracks://g')"
tracks_count=$(echo $tracks | jq '.[].file' | wc -l)
subtitles=""
for (( i = 0; i < $tracks_count; i++ ))
do
    kind=$(echo $tracks | jq .[$i].kind | sed 's/"//g')
    if [ "$kind" = "captions" ]; then
    label=$(echo $tracks | jq .[$i].label)
    file=$(echo $tracks | jq .[$i].file | sed 's/"//g')
    echo $label
    echo $file
    subtitles="--sub-file=$file $subtitles"
    fi
done
echo $subtitles

# Fetch master m3u8 file
master_m3u8_url="$(grep file: $page_file | grep -o http[^\']* )"
echo "*******************************"
echo "master_m3u8_url=$master_m3u8_url"
echo "*******************************"

master_m3u8_file=$($tempfile_cmd)

stream_directory=$(basename $(dirname $master_m3u8_url))

echo ">>> Fetching master m3u8 file: $master_m3u8_url"
wget $VERBOSITY "$WGET_PARAMETERS" \
     --output-document $master_m3u8_file \
     "$master_m3u8_url" || exit_route ">> Failed"
echo ">>> Done."

# Fetch audio urls
audios=""
for i in $(cat $master_m3u8_file  | sed -n '/TYPE=AUDIO/p' | sed -n '/DEFAULT=NO/p' | sed -e 's/^.*URI="\(.*\)"/\1/')
do
#   echo $i
    audios="--audio-file=$i $audios"
done
echo $audios

# Fetch stream m3u8 file
quality="$2"

if [ -n "$quality" ]
then
    stream_m3u8_url="$(grep -A 1 x${quality} $master_m3u8_file | sed -n 2p)"
else
    stream_m3u8_url="$(awk /./ $master_m3u8_file | tail -1)"
    quality=$(awk /./ $master_m3u8_file | tail -2 | cut -d= -f4 | cut -c6-9)
fi
echo "*******************************"
echo "stream_m3u8_url=$stream_m3u8_url"
echo "quality=$quality"
echo "*******************************"

mpv --fs --sub-font="XB Niloofar" $subtitles $audios $stream_m3u8_url
