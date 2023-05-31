#!/bin/bash

declare -r TIMER_FILE="/run/user/1000/timer.txt"

timer_stop() {
    rm $TIMER_FILE
    tput cnorm #~ включаем курсор
}

show_timer() {
    clear
    toilet -f smblock "$1" | boxes -d bear -a hc -p h8
}

timer() {
    if [[ "$PAUSED" -eq 0 ]]; then
        (( TIME += 1 ))
        TIMER=$(date -u --date='@'"$TIME" '+%H:%M:%S')
        TIMER=${TIMER##00:}
    else
        TIMER="PAUSE"
    fi
    echo "$TIMER" >$TIMER_FILE
}

timer_tick() {
    while true ; do
        read -n 2 -s -t 1 -r
        case $REPLY in
            ' ') ((PAUSED = !"$PAUSED")) ;;
        esac
        timer
        show_timer "${TIMER##00:}"
    done
}

main() {
    PAUSED=0
    TIME=0
    tput civis #~ отключаем курсор
    timer_tick
    timer_stop
}

trap "break; timer_stop; return" SIGINT
main "${@}"
exit 0
