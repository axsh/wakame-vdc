@api_from_v11.12
Feature: Volume API

  Scenario: Create and delete new volume
    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the created volumes should reach state available in 60 seconds or less

    When we make an api delete call to volumes/<registry:uuid> with no options
    Then the previous api call should be successful

  @api_from_v12.03
  Scenario: Update volume information
    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the created volumes should reach state available in 60 seconds or less

    When we make an api update call to volumes/<registry:uuid> with the following options
      | display_name |
      | volume2      |
    Then the previous api call should be successful

    When we make an api get call to volumes/<registry:uuid> with no options
    Then the previous api call should be successful
    And the previous api call should have {"display_name":} equal to "volume2"

  Scenario: Get index of volume
    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the created volumes should reach state available in 60 seconds or less

    When we make an api get call to volumes with no options
    Then the previous api call should be successful
    And the previous api call should not have [{"results":}] with a size of 0

  Scenario: Create blank volume less than minimum size
    When we make an api create call to volumes with the following options
      | volume_size | display_name |
      |           9 | volume1      |
    Then the previous api call should not be successful

  Scenario: Create minimum size blank volume
    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then the previous api call should be successful

  Scenario: Create blank volume more than maximum size
    When we make an api create call to volumes with the following options
      | volume_size | display_name |
      |        3001 | volume1      |
    Then the previous api call should not be successful

  Scenario: Create maximum size blank volume
    Given a managed volume with the following options
      | volume_size | display_name |
      |        3000 | volume1      |
    Then the previous api call should be successful

  Scenario: Attach and Detach volume to Instance
    Given the volume "wmi-lucid6" exists
      And the instance_spec "is-demospec" exists for api until 11.12

    When we save to <rule:1shot> the following options
      """
      tcp:22,22,ip4:0.0.0.0/24
      icmp:-1,-1,ip4:0.0.0.0
      """
    And we make a successful api create call to security_groups with the following options
      | description          | rule         | display_name |
      | Scenario 1shot group | <rule:1shot> | group1       |

    When we make a successful api create call to ssh_key_pairs with the following options
      | download_once | display_name |
      |             0 | group1       |

    When we successfully start an instance of wmi-lucid6 and is-demospec with the new security group and key pair
      And the created instance has reached the state "running"

    When we make a successful api create call to volumes with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then the created volumes should reach state available in 60 seconds or less

    When we successfully attach the created volume
    Then the created volumes should reach state attached in 60 seconds or less

    When we successfully detach the created volume
    Then the created volumes should reach state available in 60 seconds or less

  Scenario: Create backup from volume
    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the created volumes should reach state available in 60 seconds or less

    When we make an api put call to volumes/<registry:uuid>/backup with no options
    Then from the previous api call take {"uuid":} and save it to <registry:backup_uuid>
    And the backup_objects with id <registry:backup_uuid> should reach state "available" in 60 seconds or less

  Scenario: Create volume from backup
    Given a managed volume with the following options
      | backup_object_id | display_name |
      | bo-lucid7        | volume1      |
    Then from the previous api call take {"uuid":} and save it to <registry:uuid>
      And the created volumes should reach state available in 60 seconds or less

  @api_from_12.03
  Scenario: List volumes with filter options
    Given a managed volume with the following options
      | volume_size | service_type | display_name |
      |          10 | std          | volume1      |
    Given a managed volume with the following options
      | volume_size | service_type | display_name |
      |          20 | std          | volume2      |
    When we make an api get call to volumes with the following options
      |account_id|
      |a-shpoolxx|
    Then the previous api call should be successful
    When we make an api get call to volumes with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to volumes with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to volumes with the following options
      |display_name             |
      |volume1                  |
   Then the previous api call should be successful
