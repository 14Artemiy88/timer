#!/bin/bash
TIMER_FILE="/run/user/1000/timer.txt"
PAUSED=0

usage() {
    echo "Usage: min [sec] [-s] [-m <string>] [-i <int,unt,...> [-I <int,int,...>]"
}

function timer_stop {
    if [[ -n $1 && "$1" = true ]]; then
        clear
        # toilet -f 14 "всё!" | boxes -d bear -a hc -p h8
        toilet -f smblock "BCE!" | boxes -d bear -a hc -p h8
        rm $TIMER_FILE
        tput cnorm #~ включаем курсор
    else
        rm $TIMER_FILE
    fi
    exit
}

trap "break; timer_stop; return" SIGINT

if [[ -n $1 && $1 =~ ^-?[0-9]+$ ]]; then
    MESSAGE="динь-динь"
    SHOW_TIMER=true
    MIN=$1
    SEC=0

    if [[ -n $2 && $2 =~ ^-?[0-9]+$ ]]; then
        SEC=$2
        shift 2
    else
        shift
    fi

    while getopts ":sm:i:I:" flag; do
        case "${flag}" in
            m) MESSAGE=$OPTARG ;;
            s) SHOW_TIMER=false ;;
            i) # time left
                interval=$OPTARG
                IFS=',' read -ra interval_array <<<"$interval"
                unset IFS
                IFS=$'\n' LEFT_INTERVALS=($(sort --numeric-sort -r <<<"${interval_array[*]}"))
                unset IFS
                ;;
            I) # time passed
                Interval=$OPTARG
                IFS=',' read -ra Interval_array <<<"$Interval"
                unset IFS
                IFS=$'\n' PASSED_INTERVALS=($(sort --numeric-sort <<<"${Interval_array[*]}"))
                unset IFS
                ;;
            *)
                usage
                exit 0
                ;;
        esac
    done

    if [[ $SHOW_TIMER = true ]]; then
        tput civis #~ отключаем курсор
    fi

    START_TIME=$(date '+%s')
    ((FINISH_TIME = $START_TIME + $MIN * 60 + $SEC))

    EL_T=1
    INTERVAL_KEY=0
    PASSED_INTERVA_KEY=0
    while ((EL_T > 0)); do
        read -n 2 -s -t 1
        case $REPLY in
        ' ') ((PAUSED = !$PAUSED)) ;;
        '[A') ((FINISH_TIME = $FINISH_TIME + 60)) ;;
        '[B') ((FINISH_TIME = $FINISH_TIME - 60)) ;;
        '+') ((FINISH_TIME = $FINISH_TIME + 60)) ;;
        '-') ((FINISH_TIME = $FINISH_TIME - 60)) ;;
        esac
        if [[ ${LEFT_INTERVALS[$INTERVAL_KEY]} && $((${LEFT_INTERVALS[$INTERVAL_KEY]} * 60)) == $EL_T ]]; then
            echo "осталось ${LEFT_INTERVALS[$INTERVAL_KEY]} минут" | festival --tts --language russian >/dev/null
            # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
            ((INTERVAL_KEY = INTERVAL_KEY + 1))
        fi
        if [[ 
            ${PASSED_INTERVALS[$PASSED_INTERVA_KEY]} &&
            $((${PASSED_INTERVALS[$PASSED_INTERVA_KEY]} * 60)) == $(($FINISH_TIME - $EL_T - $START_TIME)) ]] \
            ; then
            echo "прошло ${PASSED_INTERVALS[$PASSED_INTERVA_KEY]} минут" | festival --tts --language russian >/dev/null
            # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
            ((PASSED_INTERVA_KEY = PASSED_INTERVA_KEY + 1))
        fi
        if [[ "$PAUSED" -eq 0 ]]; then
            now=$(date '+%s')
            ((EL_T = $FINISH_TIME - $now))
            TIMER=$(date -u --date='@'$EL_T '+%H:%M:%S')
            TIMER=${TIMER##00:}
            echo $TIMER >$TIMER_FILE
        else
            ((FINISH_TIME = FINISH_TIME + 1))
            TIMER="PAUSE"
        fi
        if [ "$SHOW_TIMER" = true ]; then
            clear
            toilet -f smblock ${TIMER##00:} | boxes -d bear -a hc -p h8
        fi
    done

    timer_stop $SHOW_TIMER
    echo "$MESSAGE" | festival --tts --language russian >/dev/null
    kdialog --imgbox ~/Images/D/100-1/50.jpg --title "$MESSAGE"
else
    usage
    exit 0
fi
