#!/bin/bash

# Log function
doLog(){
    msg=$(echo "$*")
    datetime=$(date "+%Y/%m/%d %H:%M:%S")

    # Print to the terminal
    test -t 1 && echo "[$datetime] $msg"
    
    # Print to logfile
    echo "[$datetime] $msg" >> "./remove-subtitle.log"
}

# If no directory is given, work in local dir
if [ "$1" == "" ]
    then
    doLog "No target path given, using working directory '$(pwd)'"
    DIR="."
else
   DIR="$1"
fi

# Get all the MKV files in this dir and its subdirs
find "$DIR" -type f -name '*.mkv' | while read filename

# For each mkv file
do

    # List for all substitles
    allSubs=$(mkvmerge -J "$filename" | jq -r '.tracks[] | select(.type=="subtitles").id')
    # List for SRT substitles only
    onlySRTSubs=$(mkvmerge -J "$filename" | jq -r '.tracks[] | select(.type=="subtitles") | select(.codec=="SubRip/SRT").id')

    # No subtitles found ? Skip to next file
    if [ "$allSubs" == "" ]
        then
        doLog "$filename : no subtitles found, skip !"
        continue
    fi

    # No SRT subtitles ? Erase all subtitles
    if [ "$onlySRTSubs" == "" ]
        then
        doLog "$filename : erase all subtitles in progress !"
        mkvSubArgument="-S"
    # All subtitles are already in SRT format
    elif [[ $allSubs == $onlySRTSubs ]]
        then
        doLog "$filename : subtitles are already in SRT format !"
        continue
    # Else, remove all non-SRT subtitles
    else
        doLog "$filename : delete of all non-SRT subtitle in progress !"
        goodSubsID=$(echo ${onlySRTSubs[@]} | tr " " ",")
        mkvSubArgument="-s $goodSubsID"
    fi

    # Silent merge
    mkvmerge $mkvSubArgument -o "${filename%.mkv}".clean.mkv "$filename" > /dev/null 2>&1 #> /dev/null 2>&1 If you want to see merging progress in terminal

    # Delete old mkv
    rm "$filename"

    # Rename new mkv
    mv "${filename%.mkv}".clean.mkv "$filename"

    # End
    doLog "$filename : done !"
done