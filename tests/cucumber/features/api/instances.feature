@api_from_v11.12
Feature: Instance API

  @api_until_v11.12
  Scenario: Create and delete new instance (volume store)
    # Security groups is an array?...
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | network_scheduler |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | false      | vif3type1         |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"
    
    When we make an api delete call to instances/<registry:id> with no options
      Then the previous api call should be successful  

  @api_until_v11.12
  Scenario: Create and delete new instance (local store)
    # Security groups is an array?...
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | network_scheduler |
      | wmi-lucid7 | is-demo2         | ssh-demo   | sg-demofgr      | false      | vif3type1         |
    Then from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"
    
    When we make an api delete call to instances/<registry:id> with no options
      Then the previous api call should be successful  

  @api_from_12.03
  Scenario: List instances with filter options
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | service_type | display_name |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | std          | instance1    |
    Given a managed instance with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | service_type | display_name |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | std          | instance2    |
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
