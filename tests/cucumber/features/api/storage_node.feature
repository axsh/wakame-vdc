Feature: Storage Node API

  Scenario: Create, update and delete for new storage node with specified UUID

    When we make an api create call to storage_nodes with the following options
      | account_id  | uuid     | node_id   | export_path  | transport_type | storage_type | ipaddr      | snapshot_base_path | offering_disk_space |
      | a-shpoolxx  | sn-test1 | sta.demo1 | /home/export | iscsi          | file         | 192.168.0.1 | /home/snapshot     | 10000               |
    Then the previous api call should be successful
      And from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the previous api call should have {"uuid":} equal to sn-test1

    When we make an api get call to storage_nodes/sn-test1 with no options
    Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to sn-test1
      And the previous api call should have {"node_id":} equal to sta.demo1
      And the previous api call should have {"export_path":} equal to /home/export
      And the previous api call should have {"transport_type":} equal to iscsi
      And the previous api call should have {"storage_type":} equal to file
      And the previous api call should have {"ipaddr":} equal to 192.168.0.1
      And the previous api call should have {"snapshot_base_path":} equal to /home/snapshot
      And the previous api call should have {"offering_disk_space":} equal to 10000

    When we make an api delete call to storage_nodes/sn-test1 with no options
    Then the previous api call should be successful
