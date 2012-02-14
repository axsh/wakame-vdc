Feature: Instance, volume and snapshot operations.

  Scenario: One shot
    Given wmi-lucid6 and is-demospec exist

    When we make a successful api create call to security_groups with the following options
    | description          | rule                     |
    | Scenario 1shot group | tcp:22,22,ip4:0.0.0.0/24\nicmp:-1,-1,ip4:0.0.0.0 |
    
    When we make a successful api create call to ssh_key_pairs with the following options
    | download_once |
    | 0             |

    When we successfully start an instance of wmi-lucid6 and is-demospec with the new security group and key pair
      And the created instance has reached the state "running"
    Then we should be able to ping the started instance in 60 seconds or less
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
    
    When we successfully create a snapshot from the created volume
    Then the created volume_snapshots should reach state available in 60 seconds or less
    
    When we successfully delete the created volumes
    Then the created volumes should reach state deleted in 60 seconds or less
    
    When we successfully create a volume from the created snapshot
    Then the created volumes should reach state available in 60 seconds or less
    
    When we successfully reboot the created instance
      And the created instance has reached the state "running"
    And we should be able to ping the started instance in 60 seconds or less
    And we should be able to log into the started instance with user ubuntu in 60 seconds or less

    When we successfully delete the created instances
      And the created instance has reached the state "terminated"
    
    When we successfully delete the created ssh_key_pairs
    And we successfully delete the created security_groups
    And we successfully delete the created volumes
    Then the created volumes should reach state deleted in 60 seconds or less
    
    When we successfully delete the created volume_snapshots
    Then the created volume_snapshots should reach state deleted in 60 seconds or less
