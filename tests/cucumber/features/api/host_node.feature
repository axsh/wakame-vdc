@api_from_v12.03
Feature: Host Node API

  Scenario: Create, update and delete for new host node with specified UUID
    Given a managed host_node with the following options
      | account_id  | uuid     | node_id   | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | a-shpoolxx  | hn-test1 | hva.demo1 | x86_64 | kvm        | 10                 | 1000                 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>
      And the previous api call should have {"uuid":} equal to "hn-test1"

    When we make an api get call to host_nodes/hn-test1 with no options
    Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to "hn-test1"
      And the previous api call should have {"node_id":} equal to "hva.demo1"
      And the previous api call should have {"arch":} equal to "x86_64"
      And the previous api call should have {"hypervisor":} equal to "kvm"
      And the previous api call should have {"offering_cpu_cores":} equal to 10
      And the previous api call should have {"offering_memory_size":} equal to 1000

    When we make an api delete call to host_nodes/hn-test1 with no options
    Then the previous api call should be successful


  Scenario: Create without node_id and success to map to unknown node.
    Given a managed host_node with the following options
      | account_id  | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | a-shpoolxx  | x86_64 | kvm        | 10                 | 1000                 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api update call to host_nodes/<hn:uuid> with the following options
      | node_id     | 
      | hva.unknown |
    Then the previous api call should be successful

    When we make an api get call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to "hva.unknown"


  Scenario: node_id should be reusable to new record.
    Given a managed host_node with the following options
      | account_id  | node_id      | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | a-shpoolxx  | hva.unknown1 | x86_64 | kvm        | 10                 | 1000                 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api delete call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful

    Given a managed host_node with the following options
      | account_id  | node_id      | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | a-shpoolxx  | hva.unknown1 | x86_64 | kvm        | 10                 | 1000                 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api get call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to "hva.unknown1"


  Scenario: node_id should only accept begin with "hva."
    When we make an api create call to host_nodes with the following options
      | account_id  | node_id      | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | a-shpoolxx  | sta.unknown1 | x86_64 | kvm        | 10                 | 1000                 |
    Then the previous api call should not be successful
