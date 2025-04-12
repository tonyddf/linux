#!/bin/sh

# Define variables
nameSession=${1:-"tmux"}
nameWindow1="Jump Server"
nameWindow2="Remote Servers"

# Determine if the session already exists
tmux has-session -t "${nameSession}" 2>/dev/null

# If the session does not exist, create it
# Otherwise, create two new windows
if [ $? != 0 ]
then
	tmux new-session -s "${nameSession}" -n "${nameWindow1}" -d
	tmux new-window -t "${nameSession}" -n "${nameWindow2}"
else
	tmux new-window -t "${nameSession}" -n "${nameWindow1}"
	tmux new-window -t "${nameSession}" -n "${nameWindow2}"
fi

# Split window 2 into four different panes
tmux select-window -t "${nameSession}":"${nameWindow2}"
tmux split-window -h \; split-window -v \; select-pane -t 0 \; split-window -v
tmux select-pane -t 0

tmux attach-session -t "${nameSession}"
