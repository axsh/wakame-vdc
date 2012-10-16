@api_from_v12.03
Feature: Backup Storage API

  Scenario: Create and delete for new backup storage
    Given a managed backup_storage with the following options
      | storage_type | base_uri                      | description   | display_name    |
      | webdav       | http://localhost:8080/images/ | test storage1 | backup storage1 |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api delete call to backup_storages/<registry:uuid> with no options
    Then the previous api call should be successful

  Scenario: Update backup storage
    Given a managed backup_storage with the following options
      | storage_type | base_uri                      | description   | display_name    |
      | webdav       | http://localhost:8080/images/ | test storage1 | backup storage1 |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>

    When we make an api update call to backup_storages/<registry:uuid> with the following options
      | description   | display_name    |
      | test storage1 | backup storage2 |
    Then the previous api call should be successful

    When we make an api get call to backup_storages/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"description":} equal to "test storage1"
    And the previous api call should have {"display_name":} equal to "backup storage2"
    And the previous api call should have {"storage_type":} equal to "webdav"
    And the previous api call should have {"base_uri":} equal to "http://localhost:8080/images/"
    And the previous api call should have {} with the key "created_at"
    And the previous api call should have {} with the key "updated_at"
    And the previous api call should have {} with the key "deleted_at"

  Scenario: Create new backup storage and fail to duplicate delete
    Given a managed backup_storage with the following options
      | storage_type | base_uri                      | description   | display_name    |
      | webdav       | http://localhost:8080/images/ | test storage1 | backup storage1 |
    And from the previous api call take {"uuid":} and save it to <registry:uuid>

    # First deletion
    When we make an api delete call to backup_storages/<registry:uuid> with no options
    Then the previous api call should be successful

    # Second deletion
    When we make an api delete call to backup_storages/<registry:uuid> with no options
    Then the previous api call should not be successful

  Scenario: Fail to create backup stroage with no options
    When we make an api create call to backup_storages/ with no options
    Then the previous api call should not be successful


  Scenario: List backup storages with filter options
    Given a managed backup_storage with the following options
      | storage_type | base_uri                      | service_type | description   | display_name    |
      | webdav       | http://localhost:8080/images/ | std          | test storage1 | backup storage1 |
    Given a managed backup_storage with the following options
      | storage_type | base_uri                      | service_type | description   | display_name    |
      | sta          | http://sta/hoge/images/       | std          | test storage2 | backup storage2 |
    When we make an api get call to backup_storages with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to backup_storages with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to backup_storages with the following options
      |display_name             |
      |backup storage1          |
    Then the previous api call should be successful

