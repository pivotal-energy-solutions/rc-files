# ============================================================================
#
# ~/.bash_profile
#
# Author: Steven K <steven@pivotalenergysolutions.com>
# Copyright 2011-2019 Pivotal Energy Solutions. All Rights Reserved.
#
# ============================================================================

# Get out of here if non-interative
[[ $- == *i* ]] || return

# Basic Functions to set up specific profiles
[[ -f ${HOME}/.debug ]] && debug=1 && export DEBUG=1
[[ ${debug} ]] && echo "Setting up defaults"

# General Specifics
export EDITOR="vi"
export CVSEDITOR=$EDITOR

export LC_CTYPE='en_US.UTF-8'
export INPUTRC="~/.inputrc"

export CVS_RSH='ssh'
export RSYNC_RSH='ssh'
export MANPAGER="less -iRMF"
export PAGER=${MANPAGER}
export LESS='-X~deMwRiPM?f%f ?e[EOF] ?lt[Line\: %lb].:?lt[Line\: %lt]. ?pt%pt\%...'

# Bash specifics
export CDPATH=".:${HOME}"
export FIGNORE=".o:~:CVS:.DS_Store:Icon*:._*:Network\ Trash\ Folder"
export FIGNORE="${FIGNORE}:.AppleDouble:.AppleDesktop:.AppleDB:Temporary\ Items"
export FIGNORE="${FIGNORE}\:2eDS_Store:\:2eVolumeIcon.icns:2eTemporaryItems"

export HISTFILE="${HOME}/.history"
export HISTTIMEFORMAT='%F %T '
export HISTCONROL="ignoredups:ignoreboth:erasedups"
export HISTFILESIZE=10000
export HISTIGNORE="top:cd /home/*:vi:ls:pwd:exit:su:df:clear:fg:bg:&:exit:df:cd"

# No auto logout
export TMOUT=0

shopt -s cdspell checkwinsize force_fignore histappend cmdhist

# use a visible bell if one is available
set bell-style visible

# Give subshells all variables
set -o allexport

# Give subshells all variables
set -o ignoreeof

# Prompt http://geoff.greer.fm/lscolors/
export CLICOLOR=1
export LSCOLORS="ExgxFxdxCxegedabagacad"
export LS_COLORS="di=1;;40:ln=36;40:so=1;;40:pi=33;40:ex=1;;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:"
export LS_COLORS="${LS_COLORS}*FAQ=1;0;01:*README=1;0;01:*INSTALL=1;0;01:*,v=5;34;93:or=01;05;31:*.c=1;33:*.C=1;33:*.h=1;33:*.cc=1;33:*.awk=1;33:*.pl=
1;33:*.py=1;33:*.pyc=1;33:*.sh=1;33:*.csh=1;33:*.vim=35:*.jpg=1;35:*.jpeg=1;35:*.JPG=1;35:*.gif=1;35:*.png=1;35:*.jpeg=1;35:*.ppm=1;35:*.pgm=1;35:*.pb
m=1;35:*.tar=1;31:*.tgz=1;31:*.gz=1;31:*.zip=1;31:*.sit=1;31:*.dmg=1;31:*.lha=1;31:*.lzh=1;31:*.arj=1;31:*.bz2=1;31:*.html=36:*.htm=36:*.o=1;36:*.a=1;
36"

# Set up Prompt..
no_color="\033[0m" #disable any colors
# regular colors
black="\033[0;30m"
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
blue="\033[0;34m"
magenta="\033[0;35m"
cyan="\033[0;36m"
white="\033[0;37m"
# emphasized (bolded) colors
eblack="\033[1;30m"
ered="\033[1;31m"
egreen="\033[1;32m"
eyellow="\033[1;33m"
eblue="\033[1;34m"
emagenta="\033[1;35m"
ecyan="\033[1;36m"
ewhite="\033[1;37m"

ret_val='$(if [[ $RET != 0 ]]; then echo -ne "\[$red\]$RET "; fi;)'
vm_val='$(if [[ $_OLD_VIRTUAL_PS1 ]]; then echo -ne " "; fi)'
time_val='$(DT=`date +%H:%M`; echo -ne "\[$cyan\][$DT]";)'
host_val='$(if [ `id -u` == 0 ]; then echo -ne "\[$magenta\][\h]"; else echo -ne "\[$green\][\h]"; fi;)'
dir_val='$(OLDIFS="$IFS"; IFS="/" ; d=3 ; p=($(echo "\w")) ; e=$((${#p[@]}-1)) ; P="\w" ;
      if [ $d -lt $e ] ; then b=$(($e-$d+1)) ; P="${p[$((b++))]}" ;
        for ((;$e-$b+1; b++)); do P="$P/${p[$b]}" ; done ;
      fi ; echo -ne "\[$yellow\]$P"; IFS=$OLDIFS;)'
end_val='$(if [ `id -u` == 0 ]; then echo -ne "\[$emagenta\]#"; else echo -ne "\[$ered\]$"; fi;)'

if [ -e ${HOME}/.server_name ]; then
    server=`cat ${HOME}/.server_name`
else
    server="UNKNOWN"
fi

export PROMPT_COMMAND='RET=$?; history -a; echo -ne "\033]0; [${server}] ${HOSTNAME%%.*} `basename \"$VIRTUAL_ENV\"`\007"'
export PS1="${ret_val}${vm_val}${time_val} ${host_val} ${dir_val} ${end_val}\[${no_color}\] "

[[ `id -u` == 0 ]] && export HOME=`cat /etc/passwd | grep ^root | cut -d ":" -f 6`
[[ `id -u` == 0 ]] && return

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias vim='vi'

# Aliases
alias env='env | egrep "^[A-Z0-9_]+=" | sort '
alias pvp='cd ~; source .venv/bin/activate'

[ -d "$HOME/.local/bin" ] && export PATH=${PATH}:"$HOME/.local/bin"

# enable color support of ls and also add handy aliases
[[ -f ${HOME}/.system_scripts ]] && . ${HOME}/.system_scripts
[[ -f ${HOME}/.bash_completions ]] && . ${HOME}/.bash_completions
[[ -f ${HOME}/.local/bin/aws_bash_completer   ]] && . ${HOME}/.local/bin/aws_bash_completer
