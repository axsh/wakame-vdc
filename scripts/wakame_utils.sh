# 
# Utilitiy function 
#  such as to control GNU screen and tmux.....
#

function abort() {
  echo $* >&2
  exit 1
}

# Run multiple sequence of comand lines
#run 'ls /'
#run 'echo && echo && ls /'
#
#run <<_END
#ls / && echo 1
#ls / || echo 2
#ls / && echo 3
#_END
function run {
  local ret=0
  if [[ -t 0 ]]; then
    eval "$*"
    ret=$?
  else
    read -u 0 -d '' i
    eval "$i"
    ret="$?"
  fi

  return $ret
}

# retry 3 /bin/ls
# echo "ls / " | retry 3
function retry {
  local retry_max="$1"
  shift

  typeset cmdlst="" i
  if [[ -t 0 ]]; then
    cmdlst="$*"
  else
    read -u 0 -d '' i
    cmdlst="$i"
  fi

  local count="$retry_max"
  local lastret=0
  while [[ $count -gt 0 ]]; do
    eval "$cmdlst"
    lastret="$?"
    [[ $lastret -eq 0 ]] && break
    count=$(($count - 1))
    echo "retry hold [$(($retry_max - $count))/${retry_max}]...."
    /bin/sleep 1
  done

  [[ ( $count -eq 0 ) && ( $lastret -ne 0 ) ]] && {
    echo "Retry failed [$retry_max]: ${*}" >&2
    return 1
  }
  return 0
}

function shlog {
  echo $* "(cwd: `pwd`)"
  eval $*
}

# for without_screen
pids=
trap 'kill -9 ${pids};' 2

function run2bg() {
  #eval "$* &"
  shlog "$* &"

  pid=$!
  echo "[pid:${pid}]# '$*'"
  pids="${pids} ${pid}"
}


###
# Control screen/tmux
###

NL=`echo -ne '\015'`

function screen_it {
  local title=$1
  local cmd=$2

  # read cmd lines from stdin
  [[ -z "$cmd"  ]] && {
    cmd="$cmd `read`"
  }

  case $screen_mode in
      'tmux')
          (tmux -S "${tmp_path}/vdc-tmux.s" list-windows -t vdc | grep ${title} >/dev/null) || {
              tmux -S "${tmp_path}/vdc-tmux.s" new-window -n "$title"
              # pipe-pane can not be called from command line in tmux version earlier than the revision below.
              # http://sourceforge.net/mailarchive/message.php?msg_id=27900401
              #tmux -v -S "${tmp_path}/vdc-tmux.s" pipe-pane -t "vdc:${title}.0" "'/bin/cat > \"${tmp_path}/screenlog.${title}\"'"
          }
          tmux -S "${tmp_path}/vdc-tmux.s" send-keys -t "vdc:${title}" "${cmd}" \; send-keys "Enter"
          ;;
      'screen')
          retry 3 screen -L -r vdc -x -X screen -t $title
          screen -L -r vdc -x -p $title -X stuff "${cmd}$NL"
          ;;
      'bg')
          run2bg "($cmd) > ${tmp_path}/vdc-${title}.log"
          ;;
      *)
          :
          ;;
  esac
}

function screen_open {
    typeset ret=0

    case $screen_mode in
        'tmux')
            echo "Creating tmux windows..."
            tmux -S "${tmp_path}/vdc-tmux.s" new-session -d -s vdc
            ret=$?
            ;;
        'screen')
            echo "Creating screen windows..."
            # screen configuration file
            /bin/cat <<EOS > "${tmp_path}/screenrc"
escape ^z^z
hardstatus on
hardstatus alwayslastline "[%m/%d %02c] %-Lw%{= BW}%50>%n%f* %t%{-}%+Lw%<" 
defscrollback 10000
logfile ${tmp_path}/screenlog.%t
logfile flush 1
EOS
            screen -L -d -m -S vdc -t vdc -c "${tmp_path}/screenrc"
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

function screen_close {
    typeset ret=0

    case $screen_mode in
        'tmux')
            tmux -S "${tmp_path}/vdc-tmux.s" has-session -t vdc && \
                tmux -S "${tmp_path}/vdc-tmux.s" kill-session -t vdc
            ret=$?
            ;;
        'screen')
            screen -ls | grep vdc >/dev/null && \
                screen -S vdc -X quit
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

function screen_attach {
    typeset ret=0

    case $screen_mode in
        'tmux')
            tmux -S "${tmp_path}/vdc-tmux.s" attach-session -t vdc
            ret=$?
            ;;
        'screen')
            screen -x -S vdc
            ret=$?
            ;;
        *)
            :
            ;;
    esac
    return $ret
}

