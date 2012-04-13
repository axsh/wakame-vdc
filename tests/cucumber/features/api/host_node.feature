@api_from_v12.03
Feature: Host Node API

  Scenario: Create, update and delete for new host node with specified UUID
    Given we save to <rand_uuid> a random uuid with the prefix "hn-"
      And we save to <rand_node_id> a random uuid with the prefix "hva."
      And a managed host_node with the following options
        | uuid        | node_id        | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
        | <rand_uuid> | <rand_node_id> | x86_64 | kvm        |                 10 |                 1000 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>
      And the previous api call should have {"uuid":} equal to <rand_uuid>

    When we make an api get call to host_nodes/<rand_uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to <rand_uuid>
      And the previous api call should have {"node_id":} equal to <rand_node_id>
      And the previous api call should have {"arch":} equal to "x86_64"
      And the previous api call should have {"hypervisor":} equal to "kvm"
      And the previous api call should have {"offering_cpu_cores":} equal to 10
      And the previous api call should have {"offering_memory_size":} equal to 1000

    When we make an api delete call to host_nodes/<rand_uuid> with no options
    Then the previous api call should be successful


  Scenario: Create without node_id and success to map to unknown node.
    Given we save to <rand_node_id> a random uuid with the prefix "hva."

    Given a managed host_node with the following options
      | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | x86_64 | kvm        | 10                 | 1000                 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api update call to host_nodes/<hn:uuid> with the following options
      | node_id        |
      | <rand_node_id> |
    Then the previous api call should be successful

    When we make an api get call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to <rand_node_id>


  Scenario: node_id should be reusable to new record.
    Given we save to <rand_node_id> a random uuid with the prefix "hva."
      And a managed host_node with the following options
      | node_id        | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | <rand_node_id> | x86_64 | kvm        |                 10 |                 1000 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api delete call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful

    Given a managed host_node with the following options
      | node_id        | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | <rand_node_id> | x86_64 | kvm        |                 10 |                 1000 |
    Then from the previous api call take {"uuid":} and save it to <hn:uuid>

    When we make an api get call to host_nodes/<hn:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to <rand_node_id>


  Scenario: node_id should only accept begin with "hva."
    Given we save to <rand_node_id> a random uuid with the prefix "sta."

    When we make an api create call to host_nodes with the following options
      | node_id        | arch   | hypervisor | offering_cpu_cores | offering_memory_size |
      | <rand_node_id> | x86_64 | kvm        |                 10 |                 1000 |
    Then the previous api call should not be successful
