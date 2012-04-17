@api_from_v12.03
Feature: Network Attachments API

  Scenario: Detach and attach from a running instance
    Given a new instance with its uuid in <instance_uuid>

    When the instance <instance_uuid> is connected to the network "nw-demo1" with the nic stored in <vif:>
      Then the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should not have {"vif":[...,{"network_id":},...]} equal to nil
      And from <vif:> take {"ipv4":{"address":}} and save it to <vif:ipv4>
      And we should be able to ping on ip <vif:ipv4> in 60 seconds or less

    When we detach from network "nw-demo1" the vif <vif:uuid>
    And we make an api get call to instances/<instance_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should have {"vif":[...,{"network_id":},...]} equal to nil
      And we should not be able to ping on ip <vif:ipv4> in 10 seconds or less

    When we attach to network "nw-demo1" the vif <vif:uuid>
    And the instance <instance_uuid> is connected to the network "nw-demo1" with the nic stored in <vif_new:>
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should not have {"vif":[...,{"network_id":},...]} equal to nil
      And we should be able to ping on ip <vif:ipv4> in 10 seconds or less


  Scenario: Detach and attach from a stopped instance
    Given a new instance with its uuid in <instance_uuid>

    When the instance <instance_uuid> is connected to the network "nw-demo1" with the nic stored in <vif:>
      Then from <vif:> take {"ipv4":{"address":}} and save it to <vif:ipv4>
      And we should be able to ping on ip <vif:ipv4> in 60 seconds or less

    When we make an api put call to instances/<instance_uuid>/stop with no options
      Then the previous api call should be successful

    When the created instance has reached the state "stopped"

    When we detach from network "nw-demo1" the vif <vif:uuid>
    And we make an api get call to instances/<instance_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should have {"vif":[...,{"network_id":},...]} equal to nil

    When we attach to network "nw-demo1" the vif <vif:uuid>
    And the instance <instance_uuid> is connected to the network "nw-demo1" with the nic stored in <vif_new:>
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should not have {"vif":[...,{"network_id":},...]} equal to nil


  Scenario: Start an instance with a detached port
    Given a new instance with its uuid in <instance_uuid>

    When the instance <instance_uuid> is connected to the network "nw-demo1" with the nic stored in <vif:>
    And we make an api put call to instances/<instance_uuid>/stop with no options
    And the created instance has reached the state "stopped"
    And we detach from network "nw-demo1" the vif <vif:uuid>
    And we make an api get call to instances/<instance_uuid> with no options
      Then the previous api call should be successful
      And from <vif:> take {"ipv4":{"address":}} and save it to <vif:ipv4>

    When we make an api put call to instances/<instance_uuid>/start with no options
      Then the previous api call should be successful

    When the created instance has reached the state "running"
      Then we should not be able to ping on ip <vif:ipv4> in 30 seconds or less
