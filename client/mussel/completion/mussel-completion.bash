# -*-Shell-script-*#
#
# requires:
#  bash
#  egrep, awk
#
# description:
#  bash-completion for mussel.sh
#

function hash_value() {
  local key=$1

  #
  # NF=2) ":id: i-xxx"
  # NF=3) "- :vif_id: vif-qqjr0ial"
  #
  egrep -w ":${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
}

_mussel.sh() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local offset=${#COMP_WORDS[@]}

  if [[ ${offset} == 1 ]]; then
    return 0
  elif [[ ${offset} == 2 ]]; then
    local namespaces="
      backup_object
      image
      instance
      load_balancer
      network
      security_group
      ssh_key_pair
    "
    COMPREPLY=($(compgen -W "${namespaces}" ${cur}))
    return 0
  elif [[ ${offset} == 3 ]]; then
    local tasks_ro="index show"
    local tasks_rw="${tasks_ro} create update destroy"

    case "${prev}" in
      image | network | backup_object)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- ${cur}))
        return 0
        ;;
      ssh_key_pair | security_group)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- ${cur}))
        return 0
        ;;
      instance)
        COMPREPLY=($(compgen -W "${tasks_rw} poweroff poweron backup" -- ${cur}))
        return 0
        ;;
      load_balancer)
        COMPREPLY=($(compgen -W "${tasks_rw} register unregister" -- ${cur}))
        return 0
        ;;
    esac
  elif [[ ${offset} == 4 ]]; then
    case "${prev}" in
      index)
        return 0
        ;;
      show | update | destroy)
        COMPREPLY=($(compgen -W "$(mussel.sh ${COMP_WORDS[1]} index | hash_value id)" -- ${cur}))
        return 0
        ;;
      poweroff | poweron | backup)
        COMPREPLY=($(compgen -W "$(mussel.sh ${COMP_WORDS[1]} index | hash_value id)" -- ${cur}))
        return 0
        ;;
      register | unregister)
        COMPREPLY=($(compgen -W "$(mussel.sh ${COMP_WORDS[1]} index | hash_value id)" -- ${cur}))
        return 0
        ;;
    esac
  fi

  local namespace=${COMP_WORDS[1]}
  local task=${COMP_WORDS[2]}

    case "${namespace}" in
      ssh_key_pair)
        case "${task}" in
          create)
            case "${prev}" in
              --public-key)
                COMPREPLY=($(compgen -f ${cur}))
                ;;
              *)
                COMPREPLY=($(compgen -W "--public-key" -- ${cur}))
                ;;
            esac
          ;;
        esac
        ;;

      security_group)
        case "${task}" in
          create)
            case "${prev}" in
              --rule)
                COMPREPLY=($(compgen -f ${cur}))
                ;;
              *)
                COMPREPLY=($(compgen -W "--rule" -- ${cur}))
                ;;
            esac
          ;;
        esac
        ;;

      instance)
        case "${task}" in
          create)
            case "${prev}" in
              --hypervisor)
                COMPREPLY=($(compgen -W "openvz lxc kvm" -- ${cur}))
                ;;
              --cpu-cores)
                COMPREPLY=($(compgen -W "1 2 4" -- ${cur}))
                ;;
              --image-id)
                COMPREPLY=($(compgen -W "$(mussel.sh image index | hash_value uuid)" -- ${cur}))
                ;;
              --memory-size)
                COMPREPLY=($(compgen -W "256 512" -- ${cur}))
                ;;
              --ssh-key-id)
                COMPREPLY=($(compgen -W "$(mussel.sh ssh_key_pair index | hash_value uuid)" -- ${cur}))
                ;;
              --vifs)
                COMPREPLY=($(compgen -f ${cur}))
                ;;
              *)
                COMPREPLY=($(compgen -W "--hypervisor --cpu-cores --image-id --memory-size --ssh-key-id --vifs" -- ${cur}))
                ;;
            esac 
            ;;
        esac
        ;;

      load_balancer)
        case "${task}" in
          create)
            case "${prev}" in
              --balance-algorithm)
                COMPREPLY=($(compgen -W "leastconn" -- ${cur}))
                ;;
              --cookie)
                COMPREPLY=($(compgen -W "haproxy" -- ${cur}))
                ;;
              --engine)
                COMPREPLY=($(compgen -W "haproxy" -- ${cur}))
                ;;
              --port | --instance-port)
                COMPREPLY=($(compgen -W "80 443" -- ${cur}))
                ;;
              --protocol | --instance-protocol)
                COMPREPLY=($(compgen -W "http https tcp" -- ${cur}))
                ;;
              --max-connection)
                COMPREPLY=($(compgen -W "1000" -- ${cur}))
                ;;
              *)
                COMPREPLY=($(compgen -W "--balance-algorithm --engine --port --instance-port --protocol --instance-protocol --max-connection" -- ${cur}))
                ;;
            esac
            ;;
          register | unregister)
            case "${prev}" in
              --vifs)
                COMPREPLY=($(compgen -W "$(mussel.sh instance index | hash_value vif_id)" -- ${cur}))
                ;;
              *)
                COMPREPLY=($(compgen -W "--vifs" -- ${cur}))
                ;;
            esac
            ;;
        esac
        ;;
    esac
}

complete -F _mussel.sh mussel.sh
