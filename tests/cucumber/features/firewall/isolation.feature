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
      icmp:-1,-1,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      icmp:-1,-1,ip4:0.0.0.0
      """
    And an instance instA1 is started in group A with scheduler vif3type1
    And an instance instA2 is started in group A with scheduler vif3type1
    And an instance instB1 is started in group B with scheduler vif3type1
    And an instance instB2 is started in group B with scheduler vif3type1
    
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
