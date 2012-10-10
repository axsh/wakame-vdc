Feature: Live security group allocation

  Scenario: Isolation
    Given security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    Given security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group C exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group D exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """

    And an instance inst1 is started in group C
    And an instance inst2 is started in group C
    And an instance inst3 is started in group C
    And an instance inst4 is started in group C

    When instance inst1 is assigned to the following groups
    | group_name |
    | A          |
    | B          |
    And we wait 3 seconds
    And instance inst2 is assigned to the following groups
    | group_name |
    | A          |
    And we wait 3 seconds
    Then instance inst1 should be able to ping instance inst2
    And instance inst2 should be able to ping instance inst1
    But instance inst1 should not be able to ping instance inst3
    And instance inst2 should not be able to ping instance inst4

    When instance inst3 is assigned to the following groups
    | group_name |
    | B          |
    And we wait 3 seconds
    Then instance inst1 should be able to ping instance inst3
    And instance inst3 should be able to ping instance inst1
    But instance inst2 should not be able to ping instance inst3
    And instance inst3 should not be able to ping instance inst2
    And instance inst1 should not be able to ping instance inst4
    And instance inst2 should not be able to ping instance inst4
    And instance inst3 should not be able to ping instance inst4

    When instance inst3 is assigned to the following groups
    | group_name |
    | A          |
    And we wait 3 seconds
    And instance inst1 is assigned to the following groups
    | group_name |
    | B          |
    And we wait 3 seconds
    Then instance inst2 should be able to ping instance inst3
    And instance inst3 should be able to ping instance inst2
    But instance inst1 should not be able to ping instance inst2
    And instance inst1 should not be able to ping instance inst3
    And instance inst2 should not be able to ping instance inst1
    And instance inst3 should not be able to ping instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    And instance inst2 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    And instance inst3 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    And instance inst4 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    Then instance inst1 should be able to ping instance inst2
    And instance inst1 should be able to ping instance inst3
    And instance inst1 should be able to ping instance inst4

    And instance inst2 should be able to ping instance inst1
    And instance inst2 should be able to ping instance inst3
    And instance inst2 should be able to ping instance inst4

    And instance inst3 should be able to ping instance inst1
    And instance inst3 should be able to ping instance inst2
    And instance inst3 should be able to ping instance inst4

    And instance inst4 should be able to ping instance inst1
    And instance inst4 should be able to ping instance inst2
    And instance inst4 should be able to ping instance inst3

    When instance inst1 is assigned to the following groups
    | group_name |
    | A          |
    And we wait 3 seconds
    And instance inst2 is assigned to the following groups
    | group_name |
    | B          |
    And we wait 3 seconds
    And instance inst3 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    And instance inst4 is assigned to the following groups
    | group_name |
    | D          |
    And we wait 3 seconds
    Then instance inst1 should not be able to ping instance inst2
    And instance inst1 should not be able to ping instance inst3
    And instance inst1 should not be able to ping instance inst4

    And instance inst2 should not be able to ping instance inst1
    And instance inst2 should not be able to ping instance inst3
    And instance inst2 should not be able to ping instance inst4

    And instance inst3 should not be able to ping instance inst1
    And instance inst3 should not be able to ping instance inst2
    And instance inst3 should not be able to ping instance inst4

    And instance inst4 should not be able to ping instance inst1
    And instance inst4 should not be able to ping instance inst2
    And instance inst4 should not be able to ping instance inst3

    When we successfully terminate instance inst1
    And we successfully terminate instance inst2
    And we successfully terminate instance inst3
    And we successfully terminate instance inst4
    And we successfully delete security group A
    And we successfully delete security group B
    And we successfully delete security group C
    And we successfully delete security group D

  Scenario: rules
    Given security group A exists with the following rules
      """
      icmp:-1,-1,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:345,345,ip4:0.0.0.0
      """
    And security group C exists with no rules
    And security group D exists with the following rules
      """
      tcp:345,345,ip4:0.0.0.0
      """
    And an instance inst1 is started in group C That listens on tcp port 345

    Then we should not be able to ping instance inst1
    And we should not be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | B          |
    And we wait 3 seconds
    Then we should not be able to ping instance inst1
    But we should be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | A          |
    And we wait 3 seconds
    Then we should be able to ping instance inst1
    But we should not be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | A          |
    | B          |
    And we wait 3 seconds
    Then we should be able to ping instance inst1
    And we should be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | C          |
    And we wait 3 seconds
    Then we should not be able to ping instance inst1
    And we should not be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | B          |
    | D          |
    And we wait 3 seconds
    Then we should not be able to ping instance inst1
    But we should be able to make a tcp connection on port 345 to instance inst1

    When instance inst1 is assigned to the following groups
    | group_name |
    | B          |
    And we wait 3 seconds
    Then we should not be able to ping instance inst1
    But we should be able to make a tcp connection on port 345 to instance inst1

    When we successfully terminate instance inst1
    And we successfully delete security group A
    And we successfully delete security group B
    And we successfully delete security group C
    And we successfully delete security group D
