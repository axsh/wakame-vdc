Feature: Static Nat

  Scenario: Static nat
    Given the security group we use allows pinging and ssh
      And the volume "wmi-secgtest" exists
      And the instance_spec "is-demospec" exists for api until 11.12

    When we successfully start instance inst1 of wmi-secgtest and is-demospec with the nat scheduler
    Then we should be able to ping its inside ip in 60 seconds or less
    And we should be able to ping its outside ip in 60 seconds or less

    When we successfully delete the created instances
    And the created instance has reached the state "terminated"
    And we successfully delete the created security_groups

  Scenario: Nat isolation
    Given the volume "wmi-secgtest" exists
    And security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:999,999,ip4:0.0.0.0
      udp:999,999,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:999,999,ip4:0.0.0.0
      udp:999,999,ip4:0.0.0.0
      """
    And a natted instance inst1 is started in group A that listens on tcp port 999 and udp port 999
    And a natted instance inst2 is started in group A that listens on tcp port 999 and udp port 999
    And a natted instance inst3 is started in group B that listens on tcp port 999 and udp port 999

    When instance inst1 sends a tcp packet to inst2's outside address on port 999
      Then it should use its outside ip
    When instance inst1 sends a tcp packet to inst2's inside address on port 999
      Then it should use its inside ip
    When instance inst1 sends a tcp packet to inst3's inside address on port 999
      Then it should fail to send the packet
    When instance inst1 sends a tcp packet to inst3's outside address on port 999
      Then it should use its outside ip

    When instance inst2 sends a tcp packet to inst1's outside address on port 999
      Then it should use its outside ip
    When instance inst2 sends a tcp packet to inst1's inside address on port 999
      Then it should use its inside ip
    When instance inst2 sends a tcp packet to inst3's inside address on port 999
      Then it should fail to send the packet
    When instance inst2 sends a tcp packet to inst3's outside address on port 999
      Then it should use its outside ip

    When instance inst3 sends a tcp packet to inst1's inside address on port 999
      Then it should fail to send the packet
    When instance inst3 sends a tcp packet to inst1's outside address on port 999
      Then it should use its outside ip
    When instance inst3 sends a tcp packet to inst2's inside address on port 999
      Then it should fail to send the packet
    When instance inst3 sends a tcp packet to inst2's outside address on port 999
      Then it should use its outside ip

    When we successfully terminate instance inst1
    And we successfully terminate instance inst2
    And we successfully terminate instance inst3
    And we successfully delete security group A
    And we successfully delete security group B
