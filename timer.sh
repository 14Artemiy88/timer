#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"
declare -r TIMER_FILE="/run/user/1000/timer.txt"

Help() {
    # Display Help
    echo "Timer with usage toilet with boxes and festival with kdialog."
    echo
    echo -e "${YELLOW_COLOR}USAGE${NORMAL_COLOR}:
    timer MIN [SEC] [OPTIONS]"
    echo
    echo -e "${YELLOW_COLOR}ARGS${NORMAL_COLOR}::
    ${GREEN_COLOR}<MIN>${NORMAL_COLOR}               Minutes
    ${GREEN_COLOR}<SEC>${NORMAL_COLOR}               Seconds [default: 0]"
    echo
    echo -e "${YELLOW_COLOR}OPTIONS${NORMAL_COLOR}::
    ${GREEN_COLOR}-i <min,...>${NORMAL_COLOR}        Notification <min> minutes before the end
    ${GREEN_COLOR}-I <min,...>${NORMAL_COLOR}        Notification <min> minutes after the start
    ${GREEN_COLOR}-m <string> ${NORMAL_COLOR}        Notification message [default: Динь-динь]
    ${GREEN_COLOR}-s${NORMAL_COLOR}                  Silent mode (without bear in terminal) [default: on]"
}

timer_stop() {
    if [[ -n $1 && "$1" = true ]]; then
        timer "BCE!"
        rm $TIMER_FILE
        tput cnorm #~ включаем курсор
    else
        rm $TIMER_FILE
    fi
}

timer() {
    clear
    # toilet -f 14 "всё!" | boxes -d bear -a hc -p h8
    toilet -f smblock "$1" | boxes -d bear -a hc -p h8
}

say() {
    echo "$1" | festival --tts --language russian >/dev/null
}

trap "break; timer_stop; return" SIGINT

if [[ -n $1 && $1 =~ ^-?[0-9]+$ ]]; then
    PAUSED=0
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
            Help
            exit 0
            ;;
        esac
    done

    if [[ $SHOW_TIMER = true ]]; then
        tput civis #~ отключаем курсор
    fi

    START_TIME=$(date '+%s')
    ((FINISH_TIME = "$START_TIME " + "$MIN" * 60 + "$SEC"))

    EL_T=1
    INTERVAL_KEY=0
    PASSED_INTERVA_KEY=0
    while ((EL_T > 0)); do
        read -n 2 -s -t 1 -r
        case $REPLY in
            ' ') ((PAUSED = !"$PAUSED")) ;;
            '[A') ((FINISH_TIME = "$FINISH_TIME" + 60)) ;;
            '[B') ((FINISH_TIME = "$FINISH_TIME" - 60)) ;;
            '+') ((FINISH_TIME = "$FINISH_TIME" + 60)) ;;
            '-') ((FINISH_TIME = "$FINISH_TIME" - 60)) ;;
        esac

        if [[
            ${#LEFT_INTERVALS[@]} -ne 0 &&
            $(( ${LEFT_INTERVALS[$INTERVAL_KEY]} * 60 )) == "$EL_T"
        ]] ; then
            say "осталось ${LEFT_INTERVALS[$INTERVAL_KEY]}  минут"
            # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
            unset "LEFT_INTERVALS[INTERVAL_KEY]"
            (( INTERVAL_KEY = INTERVAL_KEY + 1 ))
        fi
        if [[
            ${#PASSED_INTERVALS[@]} -ne 0 &&
            $(( ${PASSED_INTERVALS[$PASSED_INTERVA_KEY]} * 60 )) == "$(("$FINISH_TIME" - "$EL_T" - "$START_TIME"))"
        ]] ; then
            say "прошло ${PASSED_INTERVALS[$PASSED_INTERVA_KEY]} минут"
            # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
            unset "LEFT_INTERVALS[PASSED_INTERVA_KEY]"
            (( INTERVAL_KEY = PASSED_INTERVA_KEY+ 1 ))
        fi

        if [[ "$PAUSED" -eq 0 ]]; then
            now=$(date '+%s')
            ((EL_T = "$FINISH_TIME" - "$now"))
            TIMER=$(date -u --date='@'$EL_T '+%H:%M:%S')
            TIMER=${TIMER##00:}
            echo "$TIMER" >$TIMER_FILE
        else
            ((FINISH_TIME = FINISH_TIME + 1))
            TIMER="PAUSE"
        fi
        if [ "$SHOW_TIMER" = true ]; then
            timer "${TIMER##00:}"
        fi
    done

    timer_stop $SHOW_TIMER
    say "$MESSAGE"
#    echo "$MESSAGE" | festival --tts --language russian >/dev/null
    kdialog --imgbox ~/Images/D/100-1/50.jpg --title "$MESSAGE"
else
    Help
    exit 0
fi
