Feature: VM Isolation
    
  Scenario: Simple Isolation
    Given security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      icmp:-1,-1,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      icmp:-1,-1,ip4:0.0.0.0
      """
    And an instance instA1 is started in group A
    And an instance instA2 is started in group A
    And an instance instB1 is started in group B
    And an instance instB2 is started in group B
    
    When we wait 10 seconds
    
    When instance instA1 pings instance instA2
      Then the ping operation should be successful
    When instance instA1 pings instance instB1
      Then the ping operation should not be successful
    When instance instA1 pings instance instB2
      Then the ping operation should not be successful

    When instance instA2 pings instance instA1
      Then the ping operation should be successful
    When instance instA2 pings instance instB1
      Then the ping operation should not be successful
    When instance instA2 pings instance instB2
      Then the ping operation should not be successful
      
    When instance instB1 pings instance instB2
      Then the ping operation should be successful
    When instance instB1 pings instance instA1
      Then the ping operation should not be successful
    When instance instB1 pings instance instA2
      Then the ping operation should not be successful

    When instance instB2 pings instance instB1
      Then the ping operation should be successful
    When instance instB2 pings instance instA1
      Then the ping operation should not be successful
    When instance instB2 pings instance instA2
      Then the ping operation should not be successful
      
    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instB1
    And we successfully terminate instance instB2
    And we successfully delete security group A
    And we successfully delete security group B

  Scenario: Multiple vnic isolation
    Given security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And an instance instA1 is started in group A with 3 vnics
    And an instance instA2 is started in group A with 3 vnics
    And an instance instB1 is started in group B with 3 vnics
    And an instance instB2 is started in group B with 3 vnics
    
    When instance instA1 pings instance instA2 on each nic
      Then the ping operation should be successful for each nic
    When instance instA1 pings instance instB1 on each nic
      Then the ping operation should not be successful for each nic
    When instance instA1 pings instance instB2 on each nic
      Then the ping operation should not be successful for each nic

    When instance instA2 pings instance instA1 on each nic
      Then the ping operation should be successful for each nic
    When instance instA2 pings instance instB1 on each nic
      Then the ping operation should not be successful for each nic
    When instance instA2 pings instance instB2 on each nic
      Then the ping operation should not be successful for each nic
      
    When instance instB1 pings instance instB2 on each nic
      Then the ping operation should be successful for each nic
    When instance instB1 pings instance instA1 on each nic
      Then the ping operation should not be successful for each nic
    When instance instB1 pings instance instA2 on each nic
      Then the ping operation should not be successful for each nic

    When instance instB2 pings instance instB1 on each nic
      Then the ping operation should be successful for each nic
    When instance instB2 pings instance instA1 on each nic
      Then the ping operation should not be successful for each nic
    When instance instB2 pings instance instA2 on each nic
      Then the ping operation should not be successful for each nic
      
    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instB1
    And we successfully terminate instance instB2
    And we successfully delete security group A
    And we successfully delete security group B

  Scenario: Isolation with referencing groups
    Given the volume "wmi-secgtest" exists
      And the instance_spec "is-demospec" exists for api until 11.12
    And security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:345,345,<Group A>
      """
    And security group C exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """

    And an instance instB1 is started in group B
    And an instance instA1 is started in group A
    And an instance instA2 is started in group A
    And an instance instC1 is started in group C
    
    Then instance instA1 should be able to ping instance instA2
    And instance instA2 should be able to ping instance instA1
    But instance instA1 should not be able to ping instance instB1
    And instance instA1 should not be able to ping instance instC1
    
    When we update security group B with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    
    Then instance instA1 should be able to ping instance instA2
    And instance instA2 should be able to ping instance instA1
    But instance instA1 should not be able to ping instance instB1
    And instance instA1 should not be able to ping instance instC1
    
    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instB1
    And we successfully terminate instance instC1

    And we successfully delete security group C
    And we successfully delete security group B
    And we successfully delete security group A
