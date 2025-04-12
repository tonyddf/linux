#!/usr/bin/env bash
#### INFO #################################################################
##  Usage: start or attach to a tmux shared session in socket /tmp/tmux-shared/default
##
##  Execute from command line only
##  Run as own user
##
##  VERSION DATE      USER  CHANGES
##  1.0     20240317  ADDF  Initial version
##
############################################################################

# Define variables
SOCKET="/tmp/tmux-shared/default"
SESSION=${1:-"shared"}
WINDOW1="localhost"
WINDOW2="remote x4"

# Create a new shared tmux directoy if it does not already exist
mkdir -p -m 777 /tmp/tmux-shared

# Check if the session already exists, used for the if-statement below
tmux -S ${SOCKET} has-session -t "${SESSION}" 2>/dev/null

# If the session does not exist, create a new one
if [ $? != 0 ]
then
	tmux -S ${SOCKET} new-session -s "${SESSION}" -n "${WINDOW1}" -d
	chmod 777 ${SOCKET}
	tmux -S ${SOCKET} new-window -t "${SESSION}" -n "${WINDOW1}"

	# Split window 2 into four different panes
	tmux -S ${SOCKET} select-window -t "${SESSION}":"${WINDOW2}"
	tmux -S ${SOCKET} split-window -h \; split-window -v \; select-pane -t 0 \; split-window -v
	tmux -S ${SOCKET} select-pane -t 0
fi

# Attach to the session
tmux -S ${SOCKET} attach-session -t "${SESSION}"