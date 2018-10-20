#!/bin/bash

videoID=$1
videoURL="https://www.youtube.com/watch/?v=$videoID"
videoMinutes=$2
loop=$3
mozillaProfile="hhytcn5z"
currentDir=$(pwd)

while true; do

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

    echo "Make entry in $filepath"

    echo "user_pref(\"network.proxy.ssl\", \"$randProxy\");" >> $filepath
    echo "user_pref(\"network.proxy.ssl_port\", 8118);" >> $filepath
    echo "user_pref(\"network.proxy.http\", \"$randProxy\");" >> $filepath
    echo "user_pref(\"network.proxy.http_port\", 8118);" >> $filepath
    echo "user_pref(\"network.proxy.type\", 1);" >> $filepath
    echo "user_pref(\"app.update.enabled\", false); " >> $filepath

    # video duration

    totalDuration=$(( $videoMinutes * 60 ))
    randDuration=$(((RANDOM%$totalDuration)))

    totalDuration=$(( $videoMinutes * 60 ))
    halfDuration=$(( $totalDuration / 2 ))
    randDuration=$(((RANDOM%$halfDuration)))
    finalDuration=$(( $halfDuration + $randDuration ))

    echo "Playing video $videoURL on $randBrowser with proxy $randProxy and total duration: $finalDuration seconds"
    #command="docker run --name=youtube-player --link=youtube-proxy -d -p 6901:6901 -e VNC_RESOLUTION=800x600 -e VNC_PW="1234"  consol/ubuntu-xfce-vnc $randBrowser --proxy-server=$randProxy  https://www.youtube.com/watch?v=$1"
    command="docker run --name=youtube-player --link=youtube-proxy -d -p 6901:6901 -v $(pwd)/temp:/headless/.mozilla -e VNC_RESOLUTION=800x600 -e VNC_PW="1234"  consol/ubuntu-xfce-vnc firefox --profile=$mozillaProfile --setDefaultBrowser https://www.youtube.com/watch?v=$1 "
    #command="docker run --name=youtube-player --link=youtube-proxy -d -p 6901:6901 -v $(pwd)/temp:/headless/.mozilla -e VNC_RESOLUTION=800x600 -e VNC_PW="1234"  consol/ubuntu-xfce-vnc "
    #command="docker run --name=youtube-player --link=youtube-proxy -itd -p 6901:6901 -e VNC_RESOLUTION=800x600 -e VNC_PW="1234" -v $(pwd):/opt consol/ubuntu-xfce-vnc /bin/bash /opt/firefox.sh $videoURL $randProxy 8118 >> /opt/log.txt"
    echo $command
    $command

    sleep $finalDuration

    ## Remove docker running images
    command="docker kill $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-*")"
    $command
    command="docker rm $(docker ps -a --format '{{.Names}}' | grep -G "^youtube-*")"
    $command

done