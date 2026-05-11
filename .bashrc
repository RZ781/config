# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# If not running interactively, don't do anything

append_path () {
	case ":$PATH:" in
		::) PATH="$1" ;;
		*:"$1":*) ;;
		*) PATH="$1:$PATH"
	esac
}

append_path "/usr/bin"
append_path "/usr/sbin"
append_path "/usr/local/bin"
append_path "/usr/local/sbin"
append_path "$HOME/.local/bin"

case $- in
	*i*) ;;
	*) return;;
esac

if [ -z "$TMP" ] ; then
	TMP=/tmp
	export TMP
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

set -o vi

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set up prompt
PROMPT_DIRTRIM=3
FMT_RESET="\[\e[0m\]"
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	FMT_GREEN="\[\e[01;32m\]"
	FMT_BLUE="\[\e[01;34m\]"
	FMT_YELLOW="\[\e[01;33m\]"
fi
_PS1="$FMT_RESET$FMT_GREEN\u@void-linux$FMT_RESET:$FMT_BLUE\w$FMT_RESET$ "
PS1="$FMT_RESET\t $FMT_YELLOW(\j) $FMT_GREEN\u@\H$FMT_RESET:$FMT_BLUE\w$FMT_RESET$ "

# If this is an xterm set the title to user@host:dir
case "$TERM" in
	xterm*|rxvt*)
		PS1="\[\e]0;\D{%a %d %b} \A - ${debian_chroot:+($debian_chroot)}\u@\h - \w\a\]$PS1"
		;;
	*)
		;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	#alias dir='dir --color=auto'
	#alias vdir='vdir --color=auto'

	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias la='ls -A'
alias l='ls -CF'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

export GPG_TTY=$(tty)

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

if [ -f "$HOME/.bashrc-local" ]; then
	. "$HOME/.bashrc-local"
fi

if [ -z "$TMUX" ] ; then
	if [ -z "$SSH_TTY" ] ; then
		return
	fi
	touch $TMP/tmux-autoclose
	if tmux ls ; then
		tmux attach
	else
		tmux new-session -A -s main
	fi
	if [ -f $TMP/tmux-autoclose ] ; then
		exit
	fi
fi
