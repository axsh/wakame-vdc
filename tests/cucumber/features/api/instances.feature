@api_from_v11.12
Feature: Instance API

  Scenario: Create and delete new instance (volume store)
    # Security groups is an array?...
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | display_name |
      | wmi-lucid6 | is-small         | ssh-demo   | sg-demofgr      | false      | instance1    |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api delete call to instances/<registry:id> with no options
      Then the previous api call should be successful

  Scenario: Create and delete new instance (local store)
    # Security groups is an array?...
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | display_name |
      | wmi-lucid7 | is-small         | ssh-demo   | sg-demofgr      | false      | instance1    |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api delete call to instances/<registry:id> with no options
      Then the previous api call should be successful

  @api_from_12.03
  Scenario: Update new instance information
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | display_name |
      | wmi-lucid7 | is-small         | ssh-demo   | sg-demofgr      | false      | instance1    |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api update call to instances/<registry:id> with the following options
      | display_name |
      | instance2    |
    Then the previous api call should be successful

    When we make an api get call to instances/<registry:id> with no options
    Then the previous api call should be successful
    And the previous api call should have {"display_name":} equal to "instance2"

  Scenario: Get index of instance
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | service_type | display_name |
      | wmi-lucid7 | is-small         | ssh-demo   | sg-demofgr      | std          | instance1    |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api get call to instances with no options
    Then the previous api call should be successful
    And the previous api call should not have [{"results":}] with a size of 0

  @api_from_12.03
  Scenario: List instances with filter options
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | service_type | display_name |
      | wmi-lucid6 | is-small         | ssh-demo   | sg-demofgr      | std          | instance1    |
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | service_type | display_name |
      | wmi-lucid6 | is-small         | ssh-demo   | sg-demofgr      | std          | instance2    |
    When we make an api get call to security_groups with the following options
      |account_id|
      |a-shpoolxx|
    Then the previous api call should be successful
    When we make an api get call to instances with the following options
      |created_since            |
      |2012-01-01T21:52:11+09:00|
    Then the previous api call should be successful
    When we make an api get call to instances with the following options
      |service_type             |
      |std                      |
    Then the previous api call should be successful
    When we make an api get call to instances with the following options
      |display_name             |
      |instance1                |
    Then the previous api call should be successful

  @api_from_12.03
  Scenario: Backup image file (local store)
    Given a managed instance with the following options
      | image_id   | instance_spec_id |
      | wmi-lucid7 | is-small         |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api put call to instances/<registry:id>/backup with no options
      Then the previous api call should be successful
      Then from the previous api call take {"backup_object_id":} and save it to <registry:backup_object_id>
      Then from the previous api call take {"image_id":} and save it to <registry:image_id>

    When the backup_objects with id <registry:backup_object_id> should reach state "available" in 120 seconds or less

  @api_from_12.03
  Scenario: Poweroff and Poweron instance
    Given a managed instance with the following options
      | image_id   | cpu_cores | memory_size | quota_weight  | hypervisor       |
      | wmi-lucid7 | 1         | 256         | 1.0           | <env:HYPERVISOR> |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"

    When we make an api put call to instances/<registry:id>/poweroff with no options
      Then the previous api call should be successful
    When the created instance has reached the state "halted"
    When we make an api put call to instances/<registry:id>/poweron with no options
      Then the previous api call should be successful
    When the created instance has reached the state "running"
