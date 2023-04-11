#!/bin/bash
TIMER_FILE="/run/user/1000/timer.txt"
PAUSED=0

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

if [ -n $1 ]; then
	message="динь-динь"
	show_timer=true
	min=$1
	sec=0
	
	if [[ -n $2 && $2 =~ ^-?[0-9]+$ ]]; then
		sec=$2
		shift 2
	else
		shift
	fi
		
	while getopts ":sm:i:I:" flag; do
    	case "${flag}" in
       		m) message=$OPTARG;; 
	        s) show_timer=false;;
	        i) # time left
	        	interval=$OPTARG
        		IFS=',' read -ra interval_array <<< "$interval"; unset IFS
				IFS=$'\n' left_intervals=($(sort --numeric-sort -r <<<"${interval_array[*]}")); unset IFS
	        	;;
			I) # time passed
	        	Interval=$OPTARG
        		IFS=',' read -ra Interval_array <<< "$Interval"; unset IFS
				IFS=$'\n' passed_intervals=($(sort --numeric-sort <<<"${Interval_array[*]}")); unset IFS
	        	;;
	    esac
	done

	if [[ $show_timer = true ]]; then
		tput civis #~ отключаем курсор
	fi

	start_time=$(date '+%s')
	(( finish_time = $start_time + $min * 60 + $sec ))
	
	el_t=1
	interval_key=0
	passed_interva_key=0
	while (( el_t > 0 ))
	do
	    read -n 2 -s -t 1
	    case $REPLY in
	        ' ') (( PAUSED = !$PAUSED )) ;;
	        '[A') (( finish_time = $finish_time + 60 )) ;;
	        '[B') (( finish_time = $finish_time - 60 )) ;;
	        '+') (( finish_time = $finish_time + 60 )) ;;
	        '-') (( finish_time = $finish_time - 60 )) ;;
	    esac
	    if [[ ${left_intervals[$interval_key]} && $(( ${left_intervals[$interval_key]}*60 )) == $el_t ]]; then
			echo "осталось ${left_intervals[$interval_key]} минут" | festival --tts --language russian > /dev/null
			# kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
			(( interval_key = interval_key + 1 ))
	    fi
   	    if [[ 
   	    	${passed_intervals[$passed_interva_key]} && 
   	    	$(( ${passed_intervals[$passed_interva_key]}*60 )) == $(( $finish_time - $el_t - $start_time ))
  	    ]]; then
			echo "прошло ${passed_intervals[$passed_interva_key]} минут" | festival --tts --language russian > /dev/null
			# kdialog --imgbox ~/Images/D/100-1/50.jpg --title "динь-динь"
			(( passed_interva_key = passed_interva_key + 1 ))
	    fi
		if [[ "$PAUSED" -eq 0 ]]; then
			now=$(date '+%s')
			(( el_t = $finish_time - $now ))
			timer=$(date -u --date='@'$el_t '+%H:%M:%S')
			timer=${timer##00:}
			echo $timer > $TIMER_FILE
		else
			(( finish_time = finish_time + 1 ))
			timer="PAUSE"
		fi
		if [ "$show_timer" = true ]; then
			clear
			toilet -f smblock ${timer##00:} | boxes -d bear -a hc -p h8
		fi
	done

	timer_stop $show_timer
	echo "$message" | festival --tts --language russian > /dev/null
	kdialog --imgbox ~/Images/D/100-1/50.jpg --title "$message"
fi
