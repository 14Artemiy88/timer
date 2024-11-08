#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"
declare -r TIMER_PATH="/run/user/1000/timer"
declare -r ICON="/usr/share/icons/breeze-dark/apps/22/org.kde.ktimetracker.svg"

if [ ! -d $TIMER_PATH ]; then
    mkdir $TIMER_PATH
fi

TIMER_FILE="$TIMER_PATH/$(date +%s)"

Help() {
    # Display Help
    echo "Timer with usage toilet with boxes and festival with kdialog."
    echo
    echo -e "${YELLOW_COLOR}USAGE${NORMAL_COLOR}
    timer MIN [SEC] [OPTIONS]"
    echo
    echo -e "${YELLOW_COLOR}ARGS${NORMAL_COLOR}
    ${GREEN_COLOR}<MIN>${NORMAL_COLOR}               Minutes
    ${GREEN_COLOR}<SEC>${NORMAL_COLOR}               Seconds [default: 0]"
    echo
    echo -e "${YELLOW_COLOR}OPTIONS${NORMAL_COLOR}
    ${GREEN_COLOR}-i <min,...>${NORMAL_COLOR}        Notification <min> minutes before the end
    ${GREEN_COLOR}-I <min,...>${NORMAL_COLOR}        Notification <min> minutes after the start
    ${GREEN_COLOR}-m <string> ${NORMAL_COLOR}        Notification message [default: Динь-динь]
    ${GREEN_COLOR}-s${NORMAL_COLOR}                  Silent mode (without bear in terminal) [default: on]"
    echo
    echo -e "${YELLOW_COLOR}KEYS${NORMAL_COLOR}
    ${GREEN_COLOR}Space${NORMAL_COLOR}               Toggle pause
    ${GREEN_COLOR}Arrow up${NORMAL_COLOR},${GREEN_COLOR} +${NORMAL_COLOR}         Increase for a minute
    ${GREEN_COLOR}Arrow down${NORMAL_COLOR},${GREEN_COLOR} -${NORMAL_COLOR}       Decrease  for a minute"
}

timer_stop() {
    if [[ -n $1 && "$1" = true ]]; then
        show_timer "BCE!"
        rm $TIMER_FILE
        tput cnorm #~ включаем курсор
    else
        rm $TIMER_FILE
    fi
}

show_timer() {
    clear
    # toilet -f 14 "всё!" | boxes -d bear -a hc -p h8
    toilet -f smblock "$1" | boxes -d bear -a hc -p h8
}

say() {
    echo "$1" | festival --tts --language russian >/dev/null
}

left_interval() {
    if [[
        ${#LEFT_INTERVALS[@]} -ne 0 &&
        "${LEFT_INTERVALS[$LEFT_INTERVAL_KEY]} * 60" -eq "EL_T"
    ]] ; then
        say "осталось ${LEFT_INTERVALS[$LEFT_INTERVAL_KEY]}  минут"
        # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
        unset "LEFT_INTERVALS[LEFT_INTERVAL_KEY]"
        (( LEFT_INTERVAL_KEY += 1 ))
    fi
}

passed_interval() {
    if [[
        ${#PASSED_INTERVALS[@]} -ne 0 &&
        "${PASSED_INTERVALS[$PASSED_INTERVAL_KEY]} * 60" -eq "FINISH_TIME - EL_T - START_TIME"
    ]] ; then
        say "прошло ${PASSED_INTERVALS[$PASSED_INTERVAL_KEY]} минут"
        # kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
        unset "PASSED_INTERVALS[PASSED_INTERVAL_KEY]"
        (( PASSED_INTERVAL_KEY += 1 ))
    fi
}

timer() {
    if [[ "$PAUSED" -eq 0 ]]; then
        local now
        now=$(date '+%s')
        (( EL_T = FINISH_TIME - now ))
        TIMER=$(date -u --date='@'"$EL_T" '+%H:%M:%S')
        TIMER=${TIMER##00:}
    else
        (( FINISH_TIME += 1 ))
        TIMER="PAUSE"
        echo "$FINISH_TIME" >$TIMER_FILE
    fi
}

timer_tick() {
    START_TIME=$(date '+%s')
    (( FINISH_TIME = START_TIME + MIN*60 + SEC ))
    echo "$FINISH_TIME" >"$TIMER_FILE"
    EL_T=1
    while [[ EL_T -gt 0 ]]; do
        if [ ! -f "$TIMER_FILE" ]; then
            tput cnorm
            exit 0
        else
            FINISH_TIME=$(cat "$TIMER_FILE")
        fi
        read -n 2 -s -t 1 -r
        case $REPLY in
            ' ')  (( PAUSED = !PAUSED )) ;;
            '[A'|'+')
                (( FINISH_TIME += 60 ));
                echo "$FINISH_TIME" >"$TIMER_FILE" ;;
            '[B'|'-')
                (( FINISH_TIME -= 60 ));
                echo "$FINISH_TIME" >"$TIMER_FILE" ;;
        esac

        left_interval
        passed_interval
        timer

        if [ "$SHOW_TIMER" = true ]; then
            show_timer "${TIMER##00:}"
        fi

		
		(( percent = 100 * EL_T / (MIN*60 + SEC) ))
		if [[ $DE = "hyprland" ]]; then
        	dunstify -a "Timer" -r $START_TIME -h int:value:"$percent" -i "$ICON" "$MESSAGE" -u low
        fi
    done
}

main() {
    if ! [[ -n $1 && $1 =~ ^-?[0-9]+$ ]]; then
        Help
        exit 0
    fi

    local MESSAGE="динь-динь"
    PAUSED=0
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
            m) MESSAGE="${OPTARG}" ;;
            s) SHOW_TIMER=false ;;
            i)
                IFS=',' read -ra interval_array <<<"${OPTARG}"
                LEFT_INTERVALS="($(sort -r <<<"${interval_array[*]}"))"
                ;;
            I)
                IFS=',' read -ra Interval_array <<<"${OPTARG}"
                PASSED_INTERVALS="($(sort <<<"${Interval_array[*]}"))"
                ;;
            *) Help; exit 0 ;;
        esac
    done

    if [[ $SHOW_TIMER = true ]]; then
        tput civis #~ отключаем курсор
    fi

    timer_tick
    timer_stop $SHOW_TIMER
	if [[ $DE = "hyprland" ]]; then
		paplay --server=/run/user/1000/pulse/native /usr/share/sounds/freedesktop/stereo/complete.oga > /dev/null 2>&1
		dunstify -a "Timerdone" -r $START_TIME -i "$ICON" "$MESSAGE" -u critical
	else
		say "$MESSAGE"
		echo "$MESSAGE" | festival --tts --language russian >/dev/null
		kdialog --imgbox ~/Images/D/100-1/50.jpg --title "$MESSAGE"
	fi

}

trap "break; timer_stop; return" SIGINT

main "${@}"

exit 0
