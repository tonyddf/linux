# ┌────────────────────────────────────────────────────────────────────────────┐
# │ Script Name:    prompt.sh                                                  │
# │ Description:    Provide prompt with color, full path and git capabilities  │
# │                                                                            │
# │ Author:         Anthony Dominguez <Anthony.Dominguez@CondorEngineering.com │
# │ Created:        2026-03-14                                                 │
# │ Last Updated:   2026-03-18                                                 │
# │ Version:        1.3.1                                                      │
# │ Usage:          source prompt.sh                                           │
# │                                                                            │
# │ Notes:          none                                                       │
# │ Dependencies:   none                                                       │
# │                                                                            │
# │ Ver:   Date:       Author:     Description:                                │
# │ 1.0.0  2026-03-14  Tony        Initial version                             │
# │ 1.1.0  2026-03-15  Tony        Added information for git branch            │
# │ 1.2.0  2026-03-15  Tony        Added help option                           │
# │ 1.3.0  2026-03-17  Tony        Separated zsh and bash scripts              │
# │ 1.3.1  2026-03-18  Tony        Improved the color workflow                 │
# └────────────────────────────────────────────────────────────────────────────┘

# Define the usage function
usage() {
  cat <<EOF
Usage: source $( basename "${0}" )
       [ -h | --help ]

Configures a custom prompt for interactive Bash shells.

The prompt displays:
  - user@host
  - Full current working directory
  - git repository information when inside a git working tree, which
    includes:
      Current branch name
      Number of commits ahead of the upstream branch (↑N)
      Number of commits behind the upstream branch (↓N)
      An asterisk (*) if the working tree contains uncommitted changes

The prompt colors depend on:
  - The user, if root then user is colored red
  - The git branch is colored based on repository state:
      Red if working directory has uncommitted changes
      Yellow if changes are staged but not committed
      Magenta if branch diverges from its upstream
      Green if branch is clean and up to date

This file is intended to be sourced from a shell configuration
file (e.g. ~/.bashrc) and has no effect in non-interactive shells.

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
      shift
      return 0
      ;;
    * )
      usage
      return 1
      ;;
  esac
done


# Function git Information
__git_prompt_info() {
  # Check whether inside a Git repository
  git rev-parse --is-inside-work-tree 1>/dev/null 2>&1 || return

  # Declare local variables
  local branch=""
  local ahead=0
  local behind=0
  local arrows=""
  local untracked=""
  local dirty=""
  local staged=""

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

  # Check working tree for untracked files
  git ls-files --others --exclude-standard --directory 2>/dev/null | grep -q . && untracked="?"

  # Check working tree for unstaged changes
  git diff --no-ext-diff --quiet --exit-code 2>/dev/null || dirty="*"

  # Check working tree for staged but uncommitted changes
  git diff --no-ext-diff --quiet --cached --exit-code 2>/dev/null || staged="+"

  # Print formatted git information
  printf "%s\t%s\t%s\n" "${branch}${arrows}${dirty}${untracked}${staged}" "${ahead}" "${behind}"
}


# Function prompt update
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
  if [[ "${branch_info}" =~ [*?] ]]
  then
    # Unstaged changes or untracked files
    branch_color="${RED}"
  elif [[ "${branch_info}" =~ [+] ]]
  then
    # Staged but uncommitted changed
    branch_color="${YELLOW}"
  elif [[ ${ahead} -gt 0 || ${behind} -gt 0 ]]
  then
    # Diverged from upstream
    branch_color="${MAGENTA}"
  else
    # Clean and up to date
    branch_color="${GREEN}"
  fi

  # Define prompt without git
  PS1="${USER_COLOR}\u${RESET}@\h:\w"

  # Append git branch information to prompt
  if [[ -n "${branch_info}" ]]
  then
    PS1+=" ${branch_color}(${branch_info})${RESET}"
  fi

  # Append final prompt symbol
  PS1+=" ${PROMPT_CHAR} "
}

# Run on interactive Bash shell
if [[ -n "${BASH_VERSION}" && $- =~ i ]]
then
  # Define colors

  RESET='\[\e[0m\]'
  RED='\[\e[31m\]'
  GREEN='\[\e[32m\]'
  BLUE='\[\e[34m\]'
  MAGENTA='\[\e[35m\]'
  YELLOW='\[\e[33m\]'

  # Load git prompt helper if available
  if command -v git 1>/dev/null 2>&1
  then
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
  
  # Trigger prompt update into current shell
  PROMPT_COMMAND="__update_ps1"
else
  return
fi
