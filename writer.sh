#!/bin/bash
# writer 1.0 - @k@layer8.space - mit

nlog() {
    local ORANGE='\033[0;33m'
    local NO_COLOR='\033[0m'
    echo -e "${ORANGE}[noter] | ${1} ${NO_COLOR}"
}

mkdir -p notes
current_date=$(date +%Y-%m-%d)
nlog "opening note notes/$current_time.txt"
filename="notes/${current_date}.txt"
nano "$filename"
./noter.sh
