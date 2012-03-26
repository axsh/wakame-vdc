@api_from_v12.03
Feature: Storage Node API

  # This scenario only passes when it runs with the database contents just after installed demo data.
  # Because the same UUID is tried to use in the second time.
  Scenario: Create, update and delete for new storage node with specified UUID
    Given a managed storage_node with the following options
      | account_id  | uuid     | node_id   | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | sn-test1 | sta.test1 | /home/export | iscsi          | raw          | 192.168.0.1 | /home/snapshot     | 10000               |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the previous api call should have {"uuid":} equal to "sn-test1"

    When we make an api get call to storage_nodes/sn-test1 with no options
    Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to "sn-test1"
      And the previous api call should have {"node_id":} equal to "sta.test1"
      And the previous api call should have {"export_path":} equal to "/home/export"
      And the previous api call should have {"transport_type":} equal to "iscsi"
      And the previous api call should have {"storage_type":} equal to "raw"
      And the previous api call should have {"ipaddr":} equal to "192.168.0.1"
      And the previous api call should have {"snapshot_base_path":} equal to "/home/snapshot"
      And the previous api call should have {"offering_disk_space":} equal to 10000

    When we make an api delete call to storage_nodes/sn-test1 with no options
    Then the previous api call should be successful

  Scenario: Create without node_id and success to map to unknown node.
    Given a managed storage_node with the following options
      | account_id  | node_id     | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | sta.unknown | /home/export | iscsi          | raw          | 192.168.0.1 | /home/snapshot     | 10000               |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to storage_nodes/<registry:uuid> with the following options
      | node_id     | 
      | sta.unknown |
    Then the previous api call should be successful

    When we make an api get call to storage_nodes/<registry:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to "sta.unknown"

    When we make an api delete call to storage_nodes/<registry:uuid> with no options
    Then the previous api call should be successful


  Scenario: node_id should be reusable to new record.
    Given a managed storage_node with the following options
      | account_id  | node_id      | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | sta.unknown1 | /home/export | iscsi          | raw          | 192.168.0.1 | /home/snapshot     | 10000               |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api delete call to storage_nodes/<registry:uuid> with no options
    Then the previous api call should be successful

    Given a managed storage_node with the following options
      | account_id  | node_id      | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | sta.unknown1 | /home/export | iscsi          | raw          | 192.168.0.1 | /home/snapshot     | 10000               |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api get call to storage_nodes/<registry:uuid> with no options
    Then the previous api call should be successful
      And the previous api call should have {"node_id":} equal to "sta.unknown1"

    When we make an api delete call to storage_nodes/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: node_id should only accept begin with "sta."
    When we make an api create call to storage_nodes with the following options
      | account_id  | node_id      | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | hva.unknown2 | /home/export | iscsi          | raw          | 192.168.0.1 | /home/snapshot     | 10000               |
    Then the previous api call should not be successful
