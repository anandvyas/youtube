#!/bin/bash

mozillaProfile="hhytcn5z"
currentDir=$(pwd)

while true; do

    # Read all video from file and convert into array
    videos=()
    i=0
    while read line; do   
        videos[$i]=$line
        let i+=1    
    done < videos.txt

    count=${#videos[@]}\
    randNumber=$(((RANDOM%$count)))
    randEntity=${videos[$randNumber]}
    
    entity=($randEntity)

    # variables
    videoId=${entity[0]}
    videoMinutes=${entity[1]}

    #browser array
    #browser=('chromium-browser' 'firefox')
    browser=('chromium-browser')
    browserCount=${#browser[@]}
    browserRandNumber=$(((RANDOM%$browserCount)))
    randBrowser=${browser[$browserRandNumber]}

    # Implement TOR Proxy
    command="docker run --name youtube-proxy --restart=always -it -p 8118:8118 -d dperson/torproxy"
    $command

    # Get Proxy IP
    randProxy=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' youtube-proxy)
    randProxy="$randProxy"

    # Copy master profile to temp
    command="rm -rf $currentDir/temp"
    $command

    command="cp -r $currentDir/mozilla $currentDir/temp"
    $command

    # Make proxy entry in profile
    filepath="$currentDir/temp/firefox/$mozillaProfile.default/prefs.js"

    echo "user_pref(\"network.proxy.ssl\", \"$randProxy\");" >> $filepath
    echo "user_pref(\"network.proxy.ssl_port\", 8118);" >> $filepath
    echo "user_pref(\"network.proxy.http\", \"$randProxy\");" >> $filepath
    echo "user_pref(\"network.proxy.http_port\", 8118);" >> $filepath
    echo "user_pref(\"network.proxy.type\", 1);" >> $filepath
    echo "user_pref(\"app.update.enabled\", false); " >> $filepath

    # video duration
    totalDuration=$(( $videoMinutes * 60 ))
    halfDuration=$(( $totalDuration / 2 ))
    randDuration=$(((RANDOM%$halfDuration)))
    finalDuration=$(( $halfDuration + $randDuration ))

    echo "Video https://www.youtube.com/watch?v=$videoId" 
    echo "Browser: $randBrowser"
    echo "Proxy: $randProxy:8118"
    echo "Duration: $totalDuration finalDuration: $finalDuration"
    echo "Start time: $(date +%d/%m/%Y-%H:%M:%S)"
    
    command="docker run --name=youtube-player --link=youtube-proxy -d -p 6901:6901 -v $(pwd)/temp:/headless/.mozilla -e VNC_RESOLUTION=800x600 -e VNC_PW="1234"  consol/ubuntu-xfce-vnc firefox --profile=$mozillaProfile --setDefaultBrowser https://www.youtube.com/watch?v=$videoId "
    $command

    sleep $finalDuration

    ## Remove docker running images
    command="docker kill $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-*")"
    $command
    command="docker rm $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-*")"
    $command

done