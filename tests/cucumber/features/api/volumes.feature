Feature: Volume API

  Scenario: Create and delete new volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 10          |
    Then the previous api call should be successful
    And from the previous api call take {"uuid":} and save it to <registry:uuid>
    Then the created volumes should reach state available in 60 seconds or less
    
    When we make an api delete call to volumes/<registry:uuid> with no options
    Then the previous api call should be successful  
    
  Scenario: Create blank volume less than minimum size
    When we make an api create call to volumes with the following options
      | volume_size |
      | 9           |
    Then the previous api call should not be successful

  Scenario: Create minimum size blank volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 10          |
    Then the previous api call should be successful 

  Scenario: Create blank volume more than maximum size
    When we make an api create call to volumes with the following options
      | volume_size |
      | 3001        |
    Then the previous api call should not be successful
  
  Scenario: Create maximum size blank volume
    When we make an api create call to volumes with the following options
      | volume_size |
      | 3000        |
    Then the previous api call should be successful
  
  Scenario: Attach and Detach volume to Instance
    Given wmi-lucid6 and is-demospec exist
   
    When we make a successful api create call to security_groups with the following options
    | description          | rule                     |
    | Scenario 1shot group | tcp:22,22,ip4:0.0.0.0/24 |

    When we make a successful api create call to ssh_key_pairs with the following options
    | download_once |
    | 0             |

    When we successfully start an instance of wmi-lucid6 and is-demospec with the new security group and key pair  
    Then the created instances should reach state running in 60 seconds or less
    And we should be able to ping the started instance in 60 seconds or less
    And the started instance should start ssh in 60 seconds or less
    And we should be able to log into the started instance with user ubuntu in 60 seconds or less
    
    When we make a successful api create call to volumes with the following options
    | volume_size |
    | 10          |
    Then the created volumes should reach state available in 60 seconds or less
    
    When we successfully attach the created volume
    Then the created volumes should reach state attached in 60 seconds or less
    
    When we successfully detach the created volume
    Then the created volumes should reach state available in 60 seconds or less


