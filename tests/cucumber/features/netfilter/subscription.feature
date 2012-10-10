Feature: Event subscription

  Scenario: simple
    Given security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      icmp:-1,-1,ip4:0.0.0.0
      """
    #And there are no running instances

    When an instance instA1 is started in group A
      Then we should be subscribed to <Group A>/rules_updated
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left
      And we should be subscribed to <Group A>/referencer_added
      And we should be subscribed to <Group A>/referencer_removed

    When we successfully terminate instance instA1
      Then we should not be subscribed to <Group A>/rules_updated
      And we should not be subscribed to <Group A>/vnic_joined
      And we should not be subscribed to <Group A>/vnic_left
      And we should not be subscribed to <Group A>/referencer_added
      And we should not be subscribed to <Group A>/referencer_removed

    When we successfully delete security group A

  Scenario: extensive
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

    When an instance instB1 is started in group B
      Then we should be subscribed to <Group B>/rules_updated
      And we should be subscribed to <Group B>/vnic_joined
      And we should be subscribed to <Group B>/vnic_left
      And we should be subscribed to <Group B>/referencer_added
      And we should be subscribed to <Group B>/referencer_removed
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left

      But we should not be subscribed to <Group C>/rules_updated
      And we should not be subscribed to <Group C>/vnic_joined
      And we should not be subscribed to <Group C>/vnic_left
      And we should not be subscribed to <Group C>/referencer_added
      And we should not be subscribed to <Group C>/referencer_removed
      And we should not be subscribed to <Group A>/rules_updated
      And we should not be subscribed to <Group A>/Referencer_added
      And we should not be subscribed to <Group A>/Referencer_removed

    When we successfully terminate instance instB1
      Then we should not be subscribed to <Group B>/rules_updated
      And we should not be subscribed to <Group B>/vnic_joined
      And we should not be subscribed to <Group B>/vnic_left
      And we should not be subscribed to <Group B>/referencer_added
      And we should not be subscribed to <Group B>/referencer_removed
      And we should not be subscribed to <Group A>/vnic_joined
      And we should not be subscribed to <Group A>/vnic_left

    When an instance instB2 is started in group B
    And an instance instA1 is started in group A
      Then we should be subscribed to <Group B>/rules_updated
      And we should be subscribed to <Group B>/vnic_joined
      And we should be subscribed to <Group B>/vnic_left
      And we should be subscribed to <Group B>/referencer_added
      And we should be subscribed to <Group B>/referencer_removed
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left
      And we should be subscribed to <Group A>/rules_updated
      And we should be subscribed to <Group A>/referencer_added
      And we should be subscribed to <Group A>/referencer_removed

      But we should not be subscribed to <Group C>/rules_updated
      And we should not be subscribed to <Group C>/vnic_joined
      And we should not be subscribed to <Group C>/vnic_left
      And we should not be subscribed to <Group C>/referencer_added
      And we should not be subscribed to <Group C>/referencer_removed

    When we successfully terminate instance instA1
      Then we should be subscribed to <Group B>/rules_updated
      And we should be subscribed to <Group B>/vnic_joined
      And we should be subscribed to <Group B>/vnic_left
      And we should be subscribed to <Group B>/referencer_added
      And we should be subscribed to <Group B>/referencer_removed
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left

      But we should not be subscribed to <Group C>/rules_updated
      And we should not be subscribed to <Group C>/vnic_joined
      And we should not be subscribed to <Group C>/vnic_left
      And we should not be subscribed to <Group C>/referencer_added
      And we should not be subscribed to <Group C>/referencer_removed
      And we should not be subscribed to <Group A>/rules_updated
      And we should not be subscribed to <Group A>/referencer_added
      And we should not be subscribed to <Group A>/referencer_removed

    When an instance instA1 is started in group A
      Then we should be subscribed to <Group B>/rules_updated
      And we should be subscribed to <Group B>/vnic_joined
      And we should be subscribed to <Group B>/vnic_left
      And we should be subscribed to <Group B>/referencer_added
      And we should be subscribed to <Group B>/referencer_removed
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left
      And we should be subscribed to <Group A>/rules_updated
      And we should be subscribed to <Group A>/referencer_added
      And we should be subscribed to <Group A>/referencer_removed

      But we should not be subscribed to <Group C>/rules_updated
      And we should not be subscribed to <Group C>/vnic_joined
      And we should not be subscribed to <Group C>/vnic_left
      And we should not be subscribed to <Group C>/referencer_added
      And we should not be subscribed to <Group C>/referencer_removed

    When an instance instC1 is started in group C
      Then we should be subscribed to <Group B>/rules_updated
      And we should be subscribed to <Group B>/vnic_joined
      And we should be subscribed to <Group B>/vnic_left
      And we should be subscribed to <Group B>/referencer_added
      And we should be subscribed to <Group B>/referencer_removed
      And we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left
      And we should be subscribed to <Group A>/rules_updated
      And we should be subscribed to <Group A>/referencer_added
      And we should be subscribed to <Group A>/referencer_removed
      And we should be subscribed to <Group C>/rules_updated
      And we should be subscribed to <Group C>/vnic_joined
      And we should be subscribed to <Group C>/vnic_left
      And we should be subscribed to <Group C>/referencer_added
      And we should be subscribed to <Group C>/referencer_removed

    When we successfully terminate instance instB2
      Then we should be subscribed to <Group A>/vnic_joined
      And we should be subscribed to <Group A>/vnic_left
      And we should be subscribed to <Group A>/rules_updated
      And we should be subscribed to <Group A>/referencer_added
      And we should be subscribed to <Group A>/referencer_removed
      And we should be subscribed to <Group C>/rules_updated
      And we should be subscribed to <Group C>/vnic_joined
      And we should be subscribed to <Group C>/vnic_left
      And we should be subscribed to <Group C>/referencer_added
      And we should be subscribed to <Group C>/referencer_removed

      But we should not be subscribed to <Group B>/rules_updated
      And we should not be subscribed to <Group B>/vnic_joined
      And we should not be subscribed to <Group B>/vnic_left
      And we should not be subscribed to <Group B>/referencer_added
      And we should not be subscribed to <Group B>/referencer_removed

    When we successfully terminate instance instA1
    And we successfully terminate instance instC1
      Then we should not be subscribed to <Group B>/rules_updated
      And we should not be subscribed to <Group B>/vnic_joined
      And we should not be subscribed to <Group B>/vnic_left
      And we should not be subscribed to <Group B>/referencer_added
      And we should not be subscribed to <Group B>/referencer_removed
      And we should not be subscribed to <Group A>/vnic_joined
      And we should not be subscribed to <Group A>/vnic_left
      And we should not be subscribed to <Group A>/rules_updated
      And we should not be subscribed to <Group A>/referencer_added
      And we should not be subscribed to <Group A>/referencer_removed
      And we should not be subscribed to <Group C>/rules_updated
      And we should not be subscribed to <Group C>/vnic_joined
      And we should not be subscribed to <Group C>/vnic_left
      And we should not be subscribed to <Group C>/referencer_added
      And we should not be subscribed to <Group C>/referencer_removed

    When we successfully delete security group B
    When we successfully delete security group A
    When we successfully delete security group C
