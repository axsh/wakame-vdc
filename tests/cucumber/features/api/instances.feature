Feature: Instance API

  Scenario: Create and delete new instance
    # Security groups is an array?...
    When we make an api create call to instances with the following options
      | image_id   | instance_spec_id | ssh_key_id | security_groups | ha_enabled | network_scheduler |
      | wmi-lucid6 | is-demo2         | ssh-demo   | sg-demofgr      | false      | vif3type1         |
      Then the previous api call should be successful
      And from the previous api call take {"id":} and save it to <registry:id>

    When the created instance has reached the state "running"
    
    When we make an api delete call to instances/<registry:id> with no options
      Then the previous api call should be successful  
