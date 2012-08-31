function sctitle() { print -Pn "\ek$1\e\\"}

#命令提示符 {{{
precmd () {
RPROMPT=$(echo "%(?..$RED%?$FINISH)")

PROMPT=$(echo "$CYAN%n@$GREEN%M:$WHITE%~$FINISH
$WHITE\$$FINISH ")

case $TERM in
	(*screen*)
	sctitle "%30< ..<%~%<<"
	;;
esac
}
#}}}

#color{{{
autoload colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
colors
fi

for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
eval _$color='%{$terminfo[bold]$fg[${(L)color}]%}'
eval $color='%{$fg[${(L)color}]%}'
(( count = $count + 1 ))
done
FINISH="%{$terminfo[sgr0]%}"
#}}}

#标题栏、任务栏样式{{{
case $TERM in
	(*screen*)
	preexec() {
            sctitle '%30>..>$1%< <';
        }
	;;
	(*xterm*|*rxvt*)
	preexec() {
            print -Pn "\e]0;%~$ ${1//\\/\\\\}\a"
        }
	;;
esac
#}}}


#关于历史纪录的配置 {{{
#历史纪录条目数量
export HISTSIZE=100000000
#注销后保存的历史纪录条目数量
export SAVEHIST=100000000
#历史纪录文件
export HISTFILE=~/.zhistory
#以附加的方式写入历史纪录
setopt INC_APPEND_HISTORY
#如果连续输入的命令相同，历史纪录中只保留一个
setopt HIST_IGNORE_DUPS     
#为历史纪录中的命令添加时间戳     
setopt EXTENDED_HISTORY     

#启用 cd 命令的历史纪录，cd -[TAB]进入历史路径
setopt AUTO_PUSHD
#相同的历史路径只保留一个
setopt PUSHD_IGNORE_DUPS

#在命令前添加空格，不将此命令添加到纪录文件中
setopt HIST_IGNORE_SPACE     
#}}}

#杂项 {{{
     
#扩展路径
#/v/c/p/p => /var/cache/pacman/pkg
setopt complete_in_word

#禁用 core dumps
#limit coredumpsize 0

#Emacs风格 键绑定
#bindkey -e
bindkey -v
bindkey "\e[1~"   beginning-of-line
bindkey "\e[2~"   insert-last-word
bindkey "\e[3~"   delete-char
bindkey "\e[4~"   end-of-line
bindkey "\e[5~"   backward-word
bindkey "\e[6~"   forward-word
bindkey "\e[A"    up-line-or-search
bindkey "\e[B"    down-line-or-search
bindkey "\e[C"    forward-char
bindkey "\e[D"    backward-char
bindkey "\e[8~"   end-of-line
bindkey "\e[7~"   beginning-of-line
bindkey "\eOH"    beginning-of-line
bindkey "\eOF"    end-of-line
bindkey "\e[H"    beginning-of-line
bindkey "\e[F"    end-of-line
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix
#以下字符视为单词的一部分
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'
#}}}

#自动补全功能 {{{
setopt AUTO_LIST
setopt AUTO_MENU
#开启此选项，补全时会直接选中菜单项
#setopt MENU_COMPLETE
autoload -U compinit
compinit

_force_rehash() {
  (( CURRENT == 1 )) && rehash
  return 1	# Because we didn't really complete anything
}
zstyle ':completion:::::' completer _force_rehash _complete _approximate

#自动补全选项
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select
zstyle ':completion:*:*:default' force-list always
zstyle ':completion:*' select-prompt '%SSelect:  lines: %L  matches: %M  [%p]'
zstyle ':completion:*:match:*' original only
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:*' completer _complete _prefix _correct _prefix _match _approximate

#路径补全
zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-slashes 'yes'
zstyle ':completion::complete:*' '\\'

#彩色补全菜单
eval $(dircolors -b)
export ZLSCOLORS="${LS_COLORS}"
zmodload zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

#修正大小写
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
#错误校正     
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

compdef pkill=killall
compdef yaourt=pacman
compdef zcd=ls
compdef st=sudo
compdef service=systemctl
compdef findx=sudo
compdef lftp=sftp
compdef aftp=sftp

zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' force-list always
zstyle ':completion:*:processes' command 'ps -au$USER'

#补全类型提示分组
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[01;35m -- %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[01;31m -- No Matches Found --\e[0m'
zstyle ':completion:*:corrections' format $'\e[01;32m -- %d (errors: %e) --\e[0m'

# cd ~ 补全顺序
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
#}}}

##空行(光标在行首)补全 "cd " {{{
user-complete(){
    case $BUFFER in
        "" )                       # 空行填入 "cd "
            BUFFER="cd "
            zle end-of-line
            zle expand-or-complete
            ;;
        "cd  " )                   # TAB + 空格 替换为 "cd ~"
            BUFFER="cd ~"
            zle end-of-line
            zle expand-or-complete
            ;;
        " " )
            BUFFER="!?"
            zle end-of-line
            ;;
        "cd --" )                  # "cd --" 替换为 "cd +"
            BUFFER="cd +"
            zle end-of-line
            zle expand-or-complete
            ;;
        "cd +-" )                  # "cd +-" 替换为 "cd -"
            BUFFER="cd -"
            zle end-of-line
            zle expand-or-complete
            ;;
        * )
            zle expand-or-complete
            ;;
    esac
}

zle -N user-complete
bindkey "\t" user-complete

##在命令前插入 sudo {{{
#定义功能
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != sudo\ * ]] && BUFFER="sudo $BUFFER"
    zle end-of-line                 #光标移动到行末
}
zle -N sudo-command-line
bindkey -M viins '^k' sudo-command-line

autoload edit-command-line
zle -N edit-command-line
bindkey -M viins '^u' edit-command-line
#}}}
 
#命令别名 {{{

#[Esc][h] man 当前命令时，显示简短说明
#alias run-help >&/dev/null && unalias run-help
#autoload run-help

#}}}

#路径别名 {{{
#进入相应的路径时只要 cd ~xxx
hash -d tmp='/home/osily/tmp/'
hash -d data='/home/osily/data/'
hash -d picture='/home/osily/picture/'
hash -d music='/home/osily/music/'
hash -d book='/home/osily/book/'
#}}}
   
#{{{自定义补全
#补全 ping

zstyle ':completion:*:ping:*' hosts g.cn facebook.com 
#补全 ssh scp sftp 等
my_accounts=(
osily::1
:mirrors.163.com
:mirrors.sohu.com
:ftp.heanet.ie
:ftp.jaist.ac.jp
)
zstyle ':completion:*:my-accounts' users-hosts $my_accounts
#}}}

source $HOME/.bashrc
