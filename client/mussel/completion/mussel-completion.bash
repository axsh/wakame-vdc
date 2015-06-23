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
  local key="${1}"

  #
  # NF=2) ":id: i-xxx"
  # NF=3) "- :vif_id: vif-qqjr0ial"
  #
  case "${key}" in
    id)
      egrep -w "^  - :${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
      ;;
    *)
      egrep -w -- "- :${key}:" </dev/stdin | awk '{ if (NF == 2) {print $2} else if (NF == 3) {print $3} }'
      ;;
  esac
}

_mussel() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local offset="${#COMP_WORDS[@]}"

  if [[ "${offset}" == 1 ]]; then
    return 0
  elif [[ "${offset}" == 2 ]]; then
    local namespaces="
      alarm
      backup_object
      backup_storage
      dc_network
      host_node
      image
      instance
      instance_monitoring
      ip_handle
      ip_pool
      load_balancer
      network
      network_vif
      network_vif_monitor
      security_group
      ssh_key_pair
      storage_node
      volume
    "
    COMPREPLY=($(compgen -W "${namespaces}" "${cur}"))
    return 0
  elif [[ "${offset}" == 3 ]]; then
    local tasks_ro="index show"
    local tasks_rw="${tasks_ro} create update destroy"

    case "${prev}" in
      alarm)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- "${cur}"))
        ;;
      backup_object)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      backup_storage)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      dc_network)
        COMPREPLY=($(compgen -W "${tasks_rw} add_offering_modes" -- "${cur}"))
        ;;
      host_node)
        COMPREPLY=($(compgen -W "${tasks_ro} evacuate" -- "${cur}"))
        ;;
      image)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- "${cur}"))
        ;;
      instance)
        COMPREPLY=($(compgen -W "${tasks_rw} power{off,on} backup" -- "${cur}"))
        ;;
      instance_monitoring)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      ip_handle)
        COMPREPLY=($(compgen -W "show expire_at" -- "${cur}"))
        ;;
      ip_pool)
        COMPREPLY=($(compgen -W "${tasks_rw} ip_handles acquire release" -- "${cur}"))
        ;;
      load_balancer)
        COMPREPLY=($(compgen -W "${tasks_rw} power{off,on} {,un}register" -- "${cur}"))
        ;;
      network)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      network_vif)
        COMPREPLY=($(compgen -W "${tasks_ro} {show,attach,detach}_external_ip {add,remove}_security_group" -- "${cur}"))
        ;;
      network_vif_monitor)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      security_group)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- "${cur}"))
        ;;
      ssh_key_pair)
        COMPREPLY=($(compgen -W "${tasks_rw}" -- "${cur}"))
        ;;
      storage_node)
        COMPREPLY=($(compgen -W "${tasks_ro}" -- "${cur}"))
        ;;
      volume)
        COMPREPLY=($(compgen -W "${tasks_rw} backup attach detach" -- "${cur}"))
        ;;
    esac
    return 0
  elif [[ "${offset}" == 4 ]]; then
    local needmore=
    case "${prev}" in
      show)
        # "--is-public" for image.index.
        # this options will be ignored in other namespace.
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --is-public true | hash_value id)" -- "${cur}"))
        ;;
      destroy)
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive   | hash_value id)" -- "${cur}"))
        ;;
      poweroff)
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state running | hash_value id)" -- "${cur}"))
        ;;
      poweron)
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state halted  | hash_value id)" -- "${cur}"))
        ;;
      backup)
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive   | hash_value id)" -- "${cur}"))
        ;;
      register | unregister)
        COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state running | hash_value id)" -- "${cur}"))
        ;;
      *)
        needmore=yes
        ;;
    esac
    if [[ -z "${needmore}" ]]; then
      return 0
    fi
  fi

  local namespace="${COMP_WORDS[1]}"
  local task="${COMP_WORDS[2]}"

  case "${namespace}" in
    alarm)
      case "${task}" in
        index)
          ;;
        create)
          case "${prev}" in
            --resource-id)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --metric-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --evaluation-periods)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --notification-periods)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --description)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --params)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --ok-actions)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --alarm-actions)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --insufficient-data-actions)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "
                            --resource-id
                            --metric-name
                            --evaluation-periods
                            --notification-periods
                            --display-name
                            --description
                            --params
                            --ok-actions
                            --alarm-actions
                            --insufficient-data-actions
                            " -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --enabled)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --evaluation-periods)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --notification-periods)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --description)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --params)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --ok-actions)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --alarm-actions)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --insufficient-data-actions)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "
                                --enabled
                                --evaluation-periods
                                --notification-periods
                                --display-name
                                --description
                                --params
                                --ok-actions
                                --alarm-actions
                                --insufficient-data-actions
                                " -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    backup_object)
      ;;

    backup_storage)
      ;;

    dc_network)
      case "${task}" in
        index)
          ;;
        create)
          case "${prev}" in
            --description)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--description --name" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --allow-new-networks)
                  COMPREPLY=($(compgen -W "false true" -- "${cur}"))
                  ;;
                --description)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--allow-new-networks --description --name" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        add_offering_modes)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --mode)
                  COMPREPLY=($(compgen -W "securitygroup passthrough l2overlay" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--mode" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    host_node)
      case "${task}" in
        index)
          ;;
        evacuate)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
          esac
          ;;
      esac
      ;;

    image)
      case "${task}" in
        index)
          case "${prev}" in
            --is-public)
              COMPREPLY=($(compgen -W "true false 0 1" -- "${cur}"))
              ;;
            --service-type)
              COMPREPLY=($(compgen -W "std lb" -- "${cur}"))
              ;;
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_deleted available deleted" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--is-public --service-type --state" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--display-name" -- "${cur}"))
                  ;;
              esac
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
              COMPREPLY=($(compgen -W "std lb" -- "${cur}"))
              ;;
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_terminated without_terminated running stopped halted terminated" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--service-type --state" -- "${cur}"))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --cpu-cores)
              COMPREPLY=($(compgen -W "1 2 4" -- "${cur}"))
              ;;
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --hypervisor)
              COMPREPLY=($(compgen -W "openvz lxc kvm" -- "${cur}"))
              ;;
            --image-id)
              COMPREPLY=($(compgen -W "$(mussel image index --is-public true | hash_value id)" -- "${cur}"))
              ;;
            --memory-size)
              COMPREPLY=($(compgen -W "256 512 1024" -- "${cur}"))
              ;;
            --ssh-key-id)
              COMPREPLY=($(compgen -W "$(mussel ssh_key_pair index | hash_value id)" -- "${cur}"))
              ;;
            --user-data)
              COMPREPLY=($(compgen -f "${cur}"))
              ;;
            --vifs)
              COMPREPLY=($(compgen -f "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--cpu-cores --display-name --hypervisor --image-id --memory-size --ssh-key-id --user-data --vifs" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --ssh-key-id)
                  COMPREPLY=($(compgen -W "$(mussel ssh_key_pair index | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--display-name --ssh-key-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    instance_monitoring)
      # TODO
      ;;

    ip_handle)
      case "${task}" in
        expire_at)
          case "${offset}" in
            4)
              # it's impossible to get ip handle list in ip_handle comands without ip_pools command.
              # $ mussel ip_pool ip_handles <ipp-***>
              COMPREPLY=($(compgen -W "ip-" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --time-to)
                  COMPREPLY=($(compgen -W "1 86400 604800 2592000 31536000" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--time-to" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    ip_pool)
      case "${task}" in
        create)
          case "${prev}" in
            --dc-networks)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--dc-networks --display-name" -- "${cur}"))
              ;;
          esac
          ;;
        ip_handles)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
          esac
          ;;
        acquire)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --network-id)
                  COMPREPLY=($(compgen -W "$(mussel network index | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--network-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        release)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --ip-handle-id)
                  COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" ip_handles "${COMP_WORDS[3]}" | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--ip-handle-id" -- "${cur}"))
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
              COMPREPLY=($(compgen -W "alive alive_with_deleted running halted terminated" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--state" -- "${cur}"))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --balance-algorithm)
              COMPREPLY=($(compgen -W "leastconn source" -- "${cur}"))
              ;;
            --cookie)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --engine)
              COMPREPLY=($(compgen -W "haproxy" -- "${cur}"))
              ;;
            --port | --instance-port)
              COMPREPLY=($(compgen -W "80 443" -- "${cur}"))
              ;;
            --protocol | --instance-protocol)
              COMPREPLY=($(compgen -W "http https tcp ssl" -- "${cur}"))
              ;;
            --max-connection)
              COMPREPLY=($(compgen -W "1000 5000" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--balance-algorithm --cookie --display-name --engine --port --instance-port --protocol --instance-protocol --max-connection" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --balance-algorithm)
                  COMPREPLY=($(compgen -W "leastconn source" -- "${cur}"))
                  ;;
                --cookie)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --engine)
                  COMPREPLY=($(compgen -W "haproxy" -- "${cur}"))
                  ;;
                --port | --instance-port)
                  COMPREPLY=($(compgen -W "80 443" -- "${cur}"))
                  ;;
                --protocol | --instance-protocol)
                  COMPREPLY=($(compgen -W "http https tcp ssl" -- "${cur}"))
                  ;;
                --max-connection)
                  COMPREPLY=($(compgen -W "1000 5000" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--balance-algorithm --cookie --display-name --engine --port --instance-port --protocol --instance-protocol --max-connection" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        register | unregister)
          case "${prev}" in
            --vifs)
              COMPREPLY=($(compgen -W "$(mussel instance index --state alive | hash_value vif_id)" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--vifs" -- "${cur}"))
              ;;
          esac
          ;;
      esac
      ;;

    network)
      ;;

    network_vif)
      case "${task}" in
        index)
          ;;
        show_external_ip)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
          esac
          ;;
        add_security_group | remove_security_group)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --security-group-id)
                  COMPREPLY=($(compgen -W "$(mussel security_group index | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--security-group-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        attach_external_ip | detach_external_ip)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --ip-handle-id)
                  COMPREPLY=($(compgen -W "ip-" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--ip-handle-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    network_vif_monitor)
      # TODO
      ;;

    security_group)
      case "${task}" in
        index)
          case "${prev}" in
            --service-type)
              COMPREPLY=($(compgen -W "std lb" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--service-type" -- "${cur}"))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --rule)
              COMPREPLY=($(compgen -f "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--display-name --rule" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --rule)
                  COMPREPLY=($(compgen -f "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--display-name --rule" -- "${cur}"))
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
            --display-name)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            --public-key)
              COMPREPLY=($(compgen -f "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--display-name --public-key" -- "${cur}"))
              ;;
          esac
          ;;
        update)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --public-key)
                  COMPREPLY=($(compgen -f "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--display-name --public-key" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

    storage_node)
      ;;

    volume)
      case "${task}" in
        index)
          case "${prev}" in
            --state)
              COMPREPLY=($(compgen -W "alive alive_with_deleted available attached deleted" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--state" -- "${cur}"))
              ;;
          esac
          ;;
        create)
          case "${prev}" in
            --backup-object-id)
              COMPREPLY=($(compgen -W "$(mussel backup_object index | hash_value id)" -- "${cur}"))
              ;;
            --storage-node-id)
              COMPREPLY=($(compgen -W "$(mussel storage_node index | hash_value id)" -- "${cur}"))
              ;;
            --volume-size)
              COMPREPLY=($(compgen -W "" -- "${cur}"))
              ;;
            *)
              COMPREPLY=($(compgen -W "--backup-object-id --storage-node-id --volume-size" -- "${cur}"))
              ;;
          esac
          ;;
        backup)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --description)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --display-name)
                  COMPREPLY=($(compgen -W "" -- "${cur}"))
                  ;;
                --is-cacheable)
                  COMPREPLY=($(compgen -W "false true" -- "${cur}"))
                  ;;
                --is-public)
                  COMPREPLY=($(compgen -W "false true" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--description --display-name --is-cacheable --is-public" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        attach)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state alive | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --instance-id)
                  COMPREPLY=($(compgen -W "$(mussel instance index --state alive | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--instance-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
        detach)
          case "${offset}" in
            4)
              COMPREPLY=($(compgen -W "$(mussel "${COMP_WORDS[1]}" index --state attached | hash_value id)" -- "${cur}"))
              ;;
            *)
              case "${prev}" in
                --instance-id)
                  COMPREPLY=($(compgen -W "$(mussel instance index --state alive | hash_value id)" -- "${cur}"))
                  ;;
                *)
                  COMPREPLY=($(compgen -W "--instance-id" -- "${cur}"))
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;

  esac
}

complete -F _mussel mussel
