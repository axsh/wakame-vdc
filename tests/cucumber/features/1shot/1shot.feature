Feature: Instance, volume and snapshot operations.

  Scenario: One shot
    Given the volume "wmi-lucid6" exists
      And the instance_spec "is-demospec" exists for api until 11.12

      And a managed security_group with the following options
        | description          | rule                                             | display_name |
        | Scenario 1shot group | tcp:22,22,ip4:0.0.0.0/24\nicmp:-1,-1,ip4:0.0.0.0 | group1       |

      And a managed ssh_key_pair with the following options
        | download_once | display_name |
        |             0 | key1         |

    When we successfully start an instance of wmi-lucid6 and is-demospec with the new security group and key pair
    Then we should be able to ping the started instance in 60 seconds or less
      And the started instance should start ssh in 60 seconds or less
      And we should be able to log into the started instance with user ubuntu in 60 seconds or less

    Given a managed volume with the following options
      | volume_size | display_name |
      |          10 | volume1      |
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
