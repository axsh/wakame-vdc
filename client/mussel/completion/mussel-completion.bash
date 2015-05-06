# -*-Shell-script-*#
#
# requires:
#  bash
#  egrep, awk
#
# description:
#  bash/zsh completion support for mussel
#
# usage:
#   1) Copy this file to somewhere (e.g. ~/.mussel-completion.bash).
#   2) Add the following line to your .bashrc/.zshrc:
#       source ~/.mussel-completion.bash
#

function hash_value() {
  local key=$1

  #
  # NF=2) ":id: i-xxx"
  # NF=3) "- :vif_id: vif-qqjr0ial"
  #
  egrep -w -- "- :${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
}

_mussel() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local offset=${#COMP_WORDS[@]}

  if [[ ${offset} == 1 ]]; then
    return 0
  elif [[ ${offset} == 2 ]]; then
    local namespaces="
      alarm
      backup_object
      backup_storage
      dc_network
      host_node
      image
      instance_monitoring
      instance
      load_balancer
      ip_handle
      ip_pool
      network
      network_vif_monitor
      network_vif
      security_group
      ssh_key_pair
      storage_node
      volume
    "
    COMPREPLY=($(compgen -W "${namespaces}" ${cur}))
    return 0
  elif [[ ${offset} == 3 ]]; then
    local tasks_ro="index show"
    local tasks_rw="${tasks_ro} create update destroy"

    case "${prev}" in
      alarm \
      | backup_object \
      | backup_storage \
      | dc_network \
      | host_node \
      | instance_monitoring \
      | network \
      | network_vif_monitor \
      | network_vif \
      | storage_node \
      | volume )
        COMPREPLY=($(compgen -W "${tasks_ro}" -- ${cur}))
        ;;
      instance)
        COMPREPLY=($(compgen -W "${tasks_rw} poweroff poweron backup" -- ${cur}))
        ;;
      load_balancer)
        COMPREPLY=($(compgen -W "${tasks_rw} poweroff poweron register unregister" -- ${cur}))
        ;;
      image | ssh_key_pair | security_group)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- ${cur}))
        ;;
    esac
    return 0
  elif [[ ${offset} == 4 ]]; then
    local needmore=
    case "${prev}" in
      show)
        # "--is-public" for image.index.
        # this options will be ignored in other namespace.
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --is-public true | hash_value id)" -- ${cur}))
        ;;
      destroy)
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive   | hash_value id)" -- ${cur}))
        ;;
      poweroff)
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state running | hash_value id)" -- ${cur}))
        ;;
      poweron)
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state halted  | hash_value id)" -- ${cur}))
        ;;
      backup)
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive   | hash_value id)" -- ${cur}))
        ;;
      register | unregister)
        COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state running | hash_value id)" -- ${cur}))
        ;;
      *)
        needmore=yes
        ;;
    esac
    if [[ -z "${needmore}" ]]; then
      return 0
    fi
  fi

  local namespace=${COMP_WORDS[1]}
  local task=${COMP_WORDS[2]}

  case "${namespace}" in
    image)
      case "${task}" in
        index)
          case "${prev}" in
            --is-public)
              COMPREPLY=($(compgen -W "true false 0 1" -- ${cur}))
              ;;
            --service-type)
              COMPREPLY=($(compgen -W "std lb" -- ${cur}))
              ;;
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_deleted available deleted" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--is-public --service-type --state" -- ${cur}))
              ;;
          esac
          ;;
      esac
      ;;

    instance)
      case "${task}" in
        index)
          case "${prev}" in
            --service-type)
              COMPREPLY=($(compgen -W "std lb" -- ${cur}))
              ;;
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_terminated without_terminated running stopped halted terminated" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--service-type --state" -- ${cur}))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --hypervisor)
              COMPREPLY=($(compgen -W "openvz lxc kvm" -- ${cur}))
              ;;
            --cpu-cores)
              COMPREPLY=($(compgen -W "1 2 4" -- ${cur}))
              ;;
            --image-id)
              COMPREPLY=($(compgen -W "$(mussel image index --is-public true | hash_value id)" -- ${cur}))
              ;;
            --memory-size)
              COMPREPLY=($(compgen -W "256 512 1024" -- ${cur}))
              ;;
            --ssh-key-id)
              COMPREPLY=($(compgen -W "$(mussel ssh_key_pair index | hash_value id)" -- ${cur}))
              ;;
            --user-data)
              COMPREPLY=($(compgen -f ${cur}))
              ;;
            --vifs)
              COMPREPLY=($(compgen -f ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--hypervisor --cpu-cores --image-id --memory-size --ssh-key-id --user-data --vifs" -- ${cur}))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive | hash_value id)" -- ${cur}))
              ;;
            *)
              case "${prev}" in
                --ssh-key-id)
                  COMPREPLY=($(compgen -W "$(mussel ssh_key_pair index | hash_value id)" -- ${cur}))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--ssh-key-id" -- ${cur}))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    load_balancer)
      case "${task}" in
        index)
          case "${prev}" in
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_deleted running halted terminated" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--state" -- ${cur}))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --balance-algorithm)
              COMPREPLY=($(compgen -W "leastconn source" -- ${cur}))
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
              COMPREPLY=($(compgen -W "http https tcp ssl" -- ${cur}))
              ;;
            --max-connection)
              COMPREPLY=($(compgen -W "1000" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--balance-algorithm --engine --port --instance-port --protocol --instance-protocol --max-connection" -- ${cur}))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive | hash_value id)" -- ${cur}))
              ;;
            *)
              case "${prev}" in
                --balance-algorithm)
                  COMPREPLY=($(compgen -W "leastconn source" -- ${cur}))
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
                  COMPREPLY=($(compgen -W "http https tcp ssl" -- ${cur}))
                  ;;
                --max-connection)
                  COMPREPLY=($(compgen -W "1000" -- ${cur}))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--balance-algorithm --engine --port --instance-port --protocol --instance-protocol --max-connection" -- ${cur}))
                  ;;
              esac
              ;;
          esac
          ;;
        register | unregister)
          case "${prev}" in
            --vifs)
              COMPREPLY=($(compgen -W "$(mussel instance index --state alive | hash_value vif_id)" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--vifs" -- ${cur}))
              ;;
          esac
          ;;
      esac
      ;;

    security_group)
      case "${task}" in
        index)
          ;;
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
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive | hash_value id)" -- ${cur}))
              ;;
            *)
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
      esac
      ;;

    ssh_key_pair)
      case "${task}" in
        index)
          ;;
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
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel ${COMP_WORDS[1]} index --state alive | hash_value id)" -- ${cur}))
              ;;
            *)
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
      esac
      ;;

    volume)
      case "${task}" in
        index)
          case "${prev}" in
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_deleted available attached deleted" -- ${cur}))
              ;;
            *)
              COMPREPLY=($(compgen -W "--state" -- ${cur}))
              ;;
          esac
          ;;
      esac
      ;;

  esac
}

complete -F _mussel mussel
