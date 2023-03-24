#!/bin/bash
TIMER_FILE="/run/user/1000/timer.txt"
PAUSED=false

function timer_stop {
	# if [[ $1 = true ]]; then
		clear
		# toilet -f 14 "всё!" | boxes -d bear -a hc -p h8
		toilet -f smblock "BCE!" | boxes -d bear -a hc -p h8
		rm $TIMER_FILE
		tput cnorm #~ включаем курсор
	# else
		# rm $TIMER_FILE
	# fi
}

trap "break; timer_stop; return" SIGINT

if [[ $1 != "" ]]; then
	message="динь-динь"
	show_timer=true
	params=( "$@" )
	for (( i=1; i<=$#; i++ )) do
		case ${params[$i]} in
			"-m")
				message=${params[$i+1]} ;;
			"-s")
				show_timer=false
		esac
	done
	
	if [[ $show_timer = true ]]; then
		tput civis #~ отключаем курсор
	fi
	sec=0
	min=$1
	if [[ $2 != "" ]]; then
		sec=$2
	fi
	start_time=$(date '+%s')
	(( finish_time = $start_time + $min * 60 + $sec ))
	
	el_t=1
	while (( el_t > 0 ))
	do
	    read -n 2 -s -t 1
	    case $REPLY in
	        ' ')
				if $PAUSED
				then
					PAUSED=false
				else
					PAUSED=true
				fi
	        ;;
	        '[A')
				(( finish_time = $finish_time + 60 ))
	        ;;
	        '[B')
				(( finish_time = $finish_time - 60 ))
	        ;;
	        '+')
				(( finish_time = $finish_time + 60 ))
	        ;;
	        '-')
				(( finish_time = $finish_time - 60 ))
	        ;;
	    esac
		if [[ "$PAUSED" = false ]]; then
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

	timer_stop
	echo "$message" | festival --tts --language russian > /dev/null
	kdialog --imgbox ~/Images/D/100-1/50.jpg --title "$message"
fi
