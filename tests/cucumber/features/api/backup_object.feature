@api_from_v12.03
Feature: Backup Object API

  Scenario: Register manually and delete new backup object

    When we make a successful api create call to backup_objects with the following options
      | account_id | backup_storage_id | object_key   | size   | allocation_size | checksum  | service_type | description  | display_name   | state     |
      | a-shpoolxx | bkst-demo2        | stor/object1 | 100000 | 100000          | 123434495 | std          | test object1 | backup object1 | available |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When we make an api get call to backup_objects/<registry:id> with no options
    Then the previous api call should be successful
      And the previous api call should have {"description":} equal to "test object1"
      And the previous api call should have {"display_name":} equal to "backup object1"
      And the previous api call should have {"service_type":} equal to "std"
      And the previous api call should have {"state":} equal to "available"
      And the previous api call should have {"object_key":} equal to "stor/object1"
      And the previous api call should have {"checksum":} equal to "123434495"
      And the previous api call should have {"backup_storage_id":} equal to "bkst-demo2"

    When we make an api delete call to backup_objects/<registry:id> with no options
      Then the previous api call should be successful

  Scenario: List backup objects with filter options
    Given a managed backup_object with the following options
      | account_id | backup_storage_id | object_key   | size   | allocation_size | checksum  | service_type | description  | display_name   | state     |
      | a-shpoolxx | bkst-demo2        | stor/object1 | 100000 | 100000          | 123434495 | std          | test object1 | backup object1 | available |
    Given a managed backup_object with the following options
      | account_id | backup_storage_id | object_key   | size   | allocation_size | checksum  | service_type | description  | display_name   | state     |
      | a-shpoolxx | bkst-demo2        | stor/object2 | 200000 | 200000          | 13829399  | std          | test object2 | backup object2 | available |
    When we make an api get call to backup_objects with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to backup_objects with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to backup_objects with the following options
      | display_name            |
      | backup object1          |
    Then the previous api call should be successful
    When we make an api get call to backup_objects with the following options
      | backup_storage_id       |
      | bkst-demo2              |
    Then the previous api call should be successful
