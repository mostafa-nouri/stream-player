#!/bin/bash

quality="$2"

while read -r page_url; do
	bash.exe play.sh $page_url $quality
done < "$1"
