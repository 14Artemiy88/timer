#!/bin/bash

now=$(date '+%s')
need=$(date -d "$1":"$2":00 '+%s')
(( timer_sec = need-now ))
(( min = timer_sec/60 ))
(( sec = timer_sec%60 ))

. timer "$min" "$sec" "${@:3}"
