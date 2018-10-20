#!/bin/bash

mozillaProfile="hhytcn5z"
currentDir=$(pwd)
processId="$(date +%s)"

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

    if [ ! $videoMinutes -gt 0 ]; then
        echo "Video minutes not readable"
        $videoMinutes = 5
    fi

     # video duration
    totalDuration=$(( $videoMinutes * 60 ))
    halfDuration=$(( $totalDuration / 2 ))
    randDuration=$(((RANDOM%$halfDuration)))
    finalDuration=$(( $halfDuration + $randDuration ))
    
    #browser array
    #browser=('chromium-browser' 'firefox')
    browser=('chromium-browser')
    browserCount=${#browser[@]}
    browserRandNumber=$(((RANDOM%$browserCount)))
    randBrowser=${browser[$browserRandNumber]}

    # Implement TOR Proxy
    command="docker run --name youtube-$processId-proxy --restart=always -it -p 8118 -d dperson/torproxy"
    $command

    # Get Proxy IP
    proxyIp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' youtube-$processId-proxy)
    proxyPort="$(docker inspect --format='{{(index (index .NetworkSettings.Ports "8118/tcp") 0).HostPort}}' youtube-$processId-proxy)"
    
    # Copy master profile to temp
    command="rm -rf $currentDir/$processId"
    $command
    command="cp -r $currentDir/mozilla $currentDir/$processId"
    $command

    # Make proxy entry in profile
    filepath="$currentDir/$processId/firefox/$mozillaProfile.default/prefs.js"

    echo "user_pref(\"network.proxy.ssl\", \"$proxyIp\");" >> $filepath
    echo "user_pref(\"network.proxy.ssl_port\", $proxyPort);" >> $filepath
    echo "user_pref(\"network.proxy.http\", \"$proxyIp\");" >> $filepath
    echo "user_pref(\"network.proxy.http_port\", $proxyPort);" >> $filepath
    echo "user_pref(\"network.proxy.type\", 1);" >> $filepath
    echo "user_pref(\"app.update.enabled\", false); " >> $filepath
    
    command="docker run --name=youtube-$processId-player --link=youtube-$processId-proxy -d -p 6901 -v $(pwd)/$processId:/headless/.mozilla -e VNC_RESOLUTION=800x600 -e VNC_PW="1234"  consol/ubuntu-xfce-vnc firefox --profile=$mozillaProfile --setDefaultBrowser https://www.youtube.com/watch?v=$videoId "
    $command

    echo "Video https://www.youtube.com/watch?v=$videoId" 
    echo "Browser: $randBrowser"
    echo "Proxy: $proxyIp:$proxyPort"
    echo "Browser port $(docker inspect --format='{{(index (index .NetworkSettings.Ports "6901/tcp") 0).HostPort}}' youtube-$processId-player)"
    echo "Duration: $totalDuration finalDuration: $finalDuration"
    echo "Start time: $(date +%d/%m/%Y-%H:%M:%S)"
    
    sleep $finalDuration

    ## Remove docker running images
    command="docker kill $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-$processId-*")"
    $command
    command="docker rm $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-$processId-*")"
    $command
done