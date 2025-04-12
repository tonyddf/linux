#!/usr/bin/env bash
#### INFO #################################################################
##  Usage: start or attach to a tmux personal session in socket /tmp/tmux-<user id>/default with two windows,
##  if ran again, create an additional window split in 4
##  Execute from command line only
##  Run as own user
##
##  VERSION DATE      USER  CHANGES
##  1.0     20240317  ADDF  Initial version
##
############################################################################

# Define variables
# Socket is not necessary as we are using the user's default socket
SESSION=${1:-"tmux"}
WINDOW1="localhost"
WINDOWN="remote x4"

# It is not necessary to ensure the directory exists, it will be created automatically


# Check if the session already exists, used for the if-statement below
tmux has-session -t "${SESSION}" 2>/dev/null

# If the session does not exist, create a new one with two windows
if [ $? != 0 ]
then
	# Create new session and two windows
	tmux new-session -s "${SESSION}" -n "${WINDOW1}" -d

fi

# Split last window in four panes
tmux new-window -t "${SESSION}" -n "${WINDOWN}"
tmux select-window -t "${SESSION}":"${WINDOWN}"
tmux split-window -h \; split-window -v \; select-pane -t 0 \; split-window -v
tmux select-pane -t 0

# Attach to the session
tmux attach-session -t "${SESSION}"
