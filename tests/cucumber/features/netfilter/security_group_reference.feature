Feature: Security groups referencing other security groups

  Scenario: Simple test
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

    And an instance instB1 is started in group B that listens on tcp port 345
    And an instance instA1 is started in group A that listens on tcp port 345

    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instB1 sends a tcp packet to instance instA1 on port 345
    Then the packet should not arrive successfully

    When we successfully terminate instance instA1
    And we successfully terminate instance instB1

    And we successfully delete security group B
    And we successfully delete security group A

  Scenario: Extensive test
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

    And an instance instB1 is started in group B that listens on tcp port 345
    And an instance instA1 is started in group A that listens on tcp port 345
    And an instance instA2 is started in group A that listens on tcp port 345
    And an instance instC1 is started in group C that listens on tcp port 345

    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instA2 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instB1 sends a tcp packet to instance instA1 on port 345
    Then the packet should not arrive successfully

    When instance instB1 sends a tcp packet to instance instA2 on port 345
    Then the packet should not arrive successfully

    When instance instC1 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When we successfully start an instance instA3 in group A that listens on tcp port 345
    And instance instA3 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When we update security group B with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """

    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When instance instA2 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When instance instA3 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instA3
    And we successfully terminate instance instB1
    And we successfully terminate instance instC1

    And an instance instNewB1 is started in group B that listens on tcp port 345
    And an instance instNewA1 is started in group A that listens on tcp port 345
    And an instance instNewA2 is started in group A that listens on tcp port 345

    When instance instNewA1 sends a tcp packet to instance instNewB1 on port 345
    Then the packet should not arrive successfully

    When instance instNewA2 sends a tcp packet to instance instNewB1 on port 345
    Then the packet should not arrive successfully

    When we update security group B with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:345,345,<Group A>
      """

    When instance instNewA1 sends a tcp packet to instance instNewB1 on port 345
    Then the packet should arrive successfully

    When instance instNewA2 sends a tcp packet to instance instNewB1 on port 345
    Then the packet should arrive successfully

    When instance instNewB1 sends a tcp packet to instance instNewA1 on port 345
    Then the packet should not arrive successfully

    When instance instNewB1 sends a tcp packet to instance instNewA2 on port 345
    Then the packet should not arrive successfully

    When we successfully terminate instance instNewA1
    And we successfully terminate instance instNewA2
    And we successfully terminate instance instNewB1

    And we successfully delete security group C
    And we successfully delete security group B
    And we successfully delete security group A

  Scenario: Multiple reference
    Given the volume "wmi-secgtest" exists
      And the instance_spec "is-demospec" exists for api until 11.12
    And security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group C exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:345,345,<Group A>
      icmp:-1,-1,<Group C>
      """

    And an instance instB1 is started in group B that listens on tcp port 345
    And an instance instA1 is started in group A that listens on tcp port 345
    And an instance instA2 is started in group A that listens on tcp port 345
    And an instance instC1 is started in group C that listens on tcp port 345
    And an instance instC2 is started in group C that listens on tcp port 345

    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instA2 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instC1 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When instance instC2 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully

    When instance instC1 pings instance instB1
      Then the ping operation should be successful

    When instance instC2 pings instance instB1
      Then the ping operation should be successful

    When instance instA1 pings instance instB1
      Then the ping operation should not be successful

    When instance instA2 pings instance instB1
      Then the ping operation should not be successful

    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instB1
    And we successfully terminate instance instC1
    And we successfully terminate instance instC2

    And we successfully delete security group B
    And we successfully delete security group C
    And we successfully delete security group A
