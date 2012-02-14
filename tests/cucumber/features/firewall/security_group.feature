Feature: Security groups

  Scenario: Group rules
    Given wmi-secgtest and is-demospec exist
    When we make a successful api create call to security_groups with the following options
    | description          |
    | group rules test     |
    And we successfully start an instance of wmi-secgtest and is-demospec with the new security group
      And the created instance has reached the state "running"
    Then we should not be able to ping the created instance for 30 seconds
    And we should not be able to make a udp connection on port 999 to the instance for 30 seconds
    And we should not be able to make a tcp connection on port 22 to the instance for 30 seconds
    
    When we successfully set the following rules for the security group
      """
      icmp:-1,-1,ip4:0.0.0.0
      """
    Then we should be able to ping the started instance in 10 seconds or less
    But we should not be able to make a tcp connection on port 22 to the instance for 30 seconds
    And we should not be able to make a udp connection on port 999 to the instance for 30 seconds

    When we successfully set the following rules for the security group
      """
      tcp:22,22,ip4:0.0.0.0
      """
    Then we should be able to make a tcp connection on port 22 to the instance for 30 seconds
    But we should not be able to ping the created instance for 30 seconds
    And we should not be able to make a udp connection on port 999 to the instance for 30 seconds
    
    When we successfully set the following rules for the security group
      """
      udp:999,999,ip4:0.0.0.0
      """
    Then we should be able to make a udp connection on port 999 to the instance for 30 seconds
    But we should not be able to make a tcp connection on port 22 to the instance for 30 seconds
    And we should not be able to ping the created instance for 30 seconds

    When we successfully delete all rules from the security group
    Then we should not be able to ping the created instance for 30 seconds
    And we should not be able to make a udp connection on port 999 to the instance for 30 seconds
    And we should not be able to make a tcp connection on port 22 to the instance for 30 seconds

    When we successfully delete the created instances
    And the created instance has reached the state "terminated"
    And we successfully delete the created security_groups

  #TODO: Scenario where we test security group between instances
