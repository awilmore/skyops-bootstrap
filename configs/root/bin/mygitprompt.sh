#!/bin/bash

###########################################
# NOTE - COLOUR_PS should be exported as a
# global env var
###########################################

COLOUR_RED="\033[1;31m"
COLOUR_YELLOW="\033[0;33m"
COLOUR_GREEN="\033[1;32m"
COLOUR_GREY="\033[1;31m"

PS1="\[$COLOUR_PS\]["     # Start of with square bracket with prompt color
PS1+="\u@\h "             # Dispay user and hostname
PS1+='${PWD}'             # Display PWD
PS1+='\[$(git_colour)\]'  # Display colour based on status
PS1+='$(git_status)'      # Show status
PS1+="\[$COLOUR_PS\]]"    # Close the square bracket
PS1+="\[\e[0m\] "         # Reset the color
export PS1

function git_colour {
  local git_status="$(git status 2> /dev/null)"

  if [[ $git_status =~ "Changes not staged for commit" ]]; then
    echo -e $COLOUR_RED
  elif [[ $git_status =~ "Changes to be committed" ]]; then
    echo -e $COLOUR_RED
  elif [[ $git_status =~ "Your branch is behind" ]]; then
    echo -e $COLOUR_YELLOW
  elif [[ $git_status =~ "Your branch is ahead of" ]]; then
    echo -e $COLOUR_YELLOW
  elif [[ $git_status =~ "nothing to commit, working directory clean" ]]; then
    echo -e $COLOUR_GREEN
  else
    echo -e $COLOUR_GREY
  fi
}

function git_status {
  local status=$(__git_ps1 "(%s)")

  if [[ ! -z "$status" ]]; then
    echo " ${status}"
  fi
}
