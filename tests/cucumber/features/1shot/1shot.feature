Feature: blablabla

  Scenario: One shot
    Given snap-lucid6 exists in volume_snapshots
  
    When we make an api create call to security_groups with the following options
    | description          | rule                     |
    | Scenario 1shot group | tcp:22,22,ip4:0.0.0.0/24 |
    Then the create call to the security_groups api should be successful
    
    When we make an api create call to ssh_key_pairs with the following options
    | download_once |
    | 0             |
    Then the create call to the ssh_key_pairs api should be successful

    When we start an instance of wmi-lucid6 with the created security group and key pair
    Then the create call to the instances api should be successful
    And the created instances should reach state running in 60 seconds or less
    And we should be able to ping the started instance in 60 seconds or less
    And the started instance should start ssh in 60 seconds or less
    And we should be able to log into the started instance with user ubuntu in 60 seconds or less
    
    When we make an api create call to volumes with the following options
    | volume_size |
    | 10          |
    Then the create call to the volumes api should be successful
    And the created volumes should reach state available in 60 seconds or less
    
    When we attach the created volume
    Then the attach api call should be successful
    And the created volumes should reach state attached in 60 seconds or less
    
    When we detach the created volume
    Then the detach api call should be successful
    And the created volumes should reach state available in 60 seconds or less
    
    When we create a snapshot from the created volume
    Then the create call to the volume_snapshots api should be successful
    And the created volume_snapshots should reach state available in 60 seconds or less
    
    When we delete the created volumes
    Then the delete call to the volumes api should be successful
    And the created volumes should reach state deleted in 60 seconds or less
    
    When we create a volume from the created snapshot
    Then the create call to the volumes api should be successful
    And the created volumes should reach state available in 60 seconds or less
    
    When we reboot the created instance
    Then the update call to the instances api should be successful
    And the created instances should reach state running in 60 seconds or less
    And we should be able to ping the started instance in 60 seconds or less
    And we should be able to log into the started instance in 60 seconds or less

    When we delete the created instances
    Then the delete call to the instances api should be successful
    And the created instances should reach state terminated in 60 seconds or less
    
    When we delete the created ssh_key_pairs
    Then the delete call to the ssh_key_pairs api should be successful
    
    When we delete the created security_groups
    Then the delete call to the security_groups api should be successful

    When we delete the created volumes
    Then the delete call to the volumes api should be successful
    And the created volumes should reach state deleted in 60 seconds or less
    
    When we delete the created volume_snapshots
    Then the delete call to the volume_snapshots api should be successful
    And the created volume_snapshots should reach state deleted in 60 seconds or less
