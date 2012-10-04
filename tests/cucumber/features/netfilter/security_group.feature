Feature: Security groups

  Scenario: Group rules
    Given the volume "wmi-secgtest" exists
    And security group A exists with the following rules
      """
      icmp:-1,-1,ip4:0.0.0.0
      """

    And an instance testinst is started in group A
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

    When we successfully terminate instance testinst
    And we successfully delete security group A
