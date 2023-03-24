#!/bin/bash

ID=$1
FILE="/run/user/1000/timer.txt"

while true
do
	timer=$(cat $FILE)
    DATA="| A  | $timer |  |  |"

    qdbus org.kde.plasma.doityourselfbar /id_$ID \
          org.kde.plasma.doityourselfbar.pass "$DATA"

    sleep 1s
done
