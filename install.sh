#!/bin/bash

path=$(pwd)

sudo ln -s $path/stopwatch.sh /usr/local/bin/stopwatch
sudo ln -s $path/clock.sh /usr/local/bin/clock
sudo ln -s $path/timer.sh /usr/local/bin/timer
