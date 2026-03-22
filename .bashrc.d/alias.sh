### User specific aliases and functions


## Safety aliases
# Make remove interactive
alias rm='rm -i'

# Make copy interactive
alias cp='cp -i'

# Make move interactive
alias mv='mv -i'


## Navigation aliases (install gls with 'brew install coreutils')
# List files
alias ll='ls \
  --all \
  --color=auto \
  --group-directories-first \
  --human-readable \
  -l'

# List files by modification time
alias lt='ls \
  --all \
  --color=auto \
  --group-directories-first \
  --human-readable \
  -l \
  -t'

# List files by modification time in reverse order
alias ltr='ls \
  --all \
  --color=auto \
  --group-directories-first \
  --human-readable \
  -l \
  -t \
  -r'

# Modified SSH connection for CI/CD
alias SSH='ssh \
  -T \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o StrictHostKeyChecking=yes \
  -o ServerAliveInterval=5 \
  -o ServerAliveCountMax=1'


## Search aliases
# Make grep output with color
alias grep='grep --color=auto'


## Shell aliases
# Shorten history
alias h='history'

# Shorten clear
alias c='clear'

# Always use vim
alias vi='vim'
