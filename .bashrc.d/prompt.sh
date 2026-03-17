# ┌────────────────────────────────────────────────────────────────────────────┐
# │ Script Name:    prompt.sh                                                  │
# │ Description:    Provide prompt with color, full path and git capabilities  │
# │                                                                            │
# │ Author:         Anthony Dominguez <Anthony.Dominguez@CondorEngineering.com │
# │ Created:        2026-03-14                                                 │
# │ Last Updated:   2026-03-17                                                 │
# │ Version:        1.2.1                                                      │
# │ Usage:          source prompt.sh                                           │
# │                                                                            │
# │ Notes:          none                                                       │
# │ Dependencies:   none                                                       │
# │                                                                            │
# │ Ver:   Date:       Author:     Description:                                │
# │ 1.0.0  2026-03-14  Tony        Initial version                             │
# │ 1.1.0  2026-03-15  Tony        Added information for git branch            │
# │ 1.2.0  2026-03-15  Tony        Added help option                           │
# │ 1.2.1  2026-03-17  Tony        Changed script name                         │
# └────────────────────────────────────────────────────────────────────────────┘

# Define the usage function
usage() {
  cat <<EOF
Usage: source $( basename "${0}" )
       [ -h | --help ]

Configures a custom prompt for interactive Bash or Zsh shells.

The prompt displays:
  - user@host
  - Full current working directory
  - Git repository information when inside a Git working tree, which
    includes:
      Current branch name
      Number of commits ahead of the upstream branch (↑N)
      Number of commits behind the upstream branch (↓N)
      An asterisk (*) if the working tree contains uncommitted changes

The prompt colors depend on:
  - The user, if root then user is colored red
  - The Git branch is colored based on repository state:
      Green if branch is up to date
      Yellow if working tree contains uncommitted changes
      Magenta if branch diverges from its upstream

This file is intended to be sourced from a shell configuration
file (e.g. ~/.bashrc or ~/.zshrc) and has no effect in
non-interactive shells.

RETURN CODES
  0       Success
  1       Unknown option
EOF
}

# If script is run directly, print usage and exit
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  usage
  exit 0
fi

# Extract options and flags
while true
do
  case "${1:-}" in
    "" )
      break
      ;;
    -h | --help )
      usage
      return 0
      ;;
    * )
      usage
      return 1
      ;;
  esac
done


# Run on interactive bash shell
if [[ -n "${BASH_VERSION}" && $- =~ i ]]
then
  # Define colors
  RESET='\[\e[0m\]'
  RED='\[\e[31m\]'
  GREEN='\[\e[32m\]'
  BLUE='\[\e[34m\]'
  MAGENTA='\[\e[35m\]'
  YELLOW='\[\e[33m\]'
# Run on interactive z shell
elif [[ -n "${ZSH_VERSION}" && $- =~ i ]]
then
  autoload -U colors && colors
  RESET='%f'
  RED='%F{red}'
  GREEN='%F{green}'
  BLUE='%F{blue}'
  MAGENTA='%F{magenta}'
  YELLOW='%F{yellow}'
else
  return
fi
  
# Load git prompt helper if available
if command -v git 1>/dev/null 2>&1
then
  # For macOS
  if [[ -r /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh ]]
  then
    source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
  fi
  # For RHEL v8
  if [[ -r /usr/share/git-core/contrib/completion/git-prompt.sh ]]
  then
    source /usr/share/git-core/contrib/completion/git-prompt.sh
  # For RHEL v9+
  elif [[ -r /usr/share/git/completion/git-prompt.sh ]]
  then
    source /usr/share/git/completion/git-prompt.sh
  fi
fi

# Enable git status indicators in the branch display
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=auto


# Function git Information
__git_prompt_info() {
  # Check whether inside a Git repository
  git rev-parse --is-inside-work-tree 1>/dev/null 2>&1 || return

  # Declare local variables
  local branch=""
  local ahead=0
  local behind=0
  local arrows=""
  local dirty=""

  # Get current branch name
  # If HEAD is detached, fall back to short commit hash
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
           || git rev-parse --short HEAD)

  # Check whether an upstream branch exists
  # Usually origin/<branch>
  if git rev-parse @{upstream} 1>/dev/null 2>&1
  then
    # Compare local branch to upstream branch
    # Output: "ahead behind"
    read ahead behind < <(
      git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
    )
  fi

  # Show number of commits ahead of upstream
  [[ ${ahead} -gt 0 ]] && arrows+="↑${ahead}"

  # Show number of commits behind upstream
  [[ ${behind} -gt 0 ]] && arrows+="↓${behind}"

  # Check if working tree has modifications
  # Faster than git status
  git diff --no-ext-diff --quiet --exit-code 2>/dev/null || dirty="*"

  # Print formatted git information
  printf "%s\t%s\t%s\n" "${branch}${arrows}${dirty}" "${ahead}" "${behind}"
}


# Function Prompt Update
__update_ps1() {
  # Change user color and prompt char based on privilege level
  if [[ ${EUID} -eq 0 ]]
  then
    USER_COLOR="${RED}"
    PROMPT_CHAR="#"
  else
    USER_COLOR="${RESET}"
    PROMPT_CHAR="$"
  fi

  # Declare local variables
  local branch_info=""
  local branch_color="${GREEN}"
  local ahead=0 
  local behind=0

  # Read result from function git prompt info
  IFS=$'\t' read -r branch_info ahead behind < <(__git_prompt_info)

  # Define color for git part of prompt
  if [[ ${ahead} -gt 0 || ${behind} -gt 0 ]]
  then
    # Out of sync with upstream
    branch_color="${MAGENTA}"
  elif [[ "${branch_info}" == *"*" ]]; then
    # Dirty working tree
    branch_color="${YELLOW}"
  fi

  # Define prompt without git
  if [[ -n "${BASH_VERSION}" ]]
  then
    # Base prompt for bash
    PROMPT="${USER_COLOR}\u${RESET}@\h:\w"
  elif [[ -n "${ZSH_VERSION}" ]]
  then
    # Base prompt for z
    PROMPT="${USER_COLOR}%n${RESET}@%m:%~"
  fi

  # Append git branch information to prompt
  if [[ -n "${branch_info}" ]]
  then
    PROMPT+=" ${branch_color}(${branch_info})${RESET}"
  fi

  # Append Final prompt symbol
  PROMPT+=" ${PROMPT_CHAR} "
}


# Hook prompt update into the current shell
if [[ -n "${BASH_VERSION}" ]]
then
  PROMPT_COMMAND="__update_ps1"
elif [[ -n "${ZSH_VERSION}" ]]
then
  precmd() { __update_ps1; }
fi
