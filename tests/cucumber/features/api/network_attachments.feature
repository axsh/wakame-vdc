@api_from_v12.03
Feature: Network Port Attachments API

  # Clean up this mess...
  Scenario: Attachment lifecycle
    Given a new network with its uuid in <registry:network_uuid>
    And a new instance with its uuid in <registry:instance_uuid>
    # And a new port in <registry:network_uuid> with its uuid in <registry:port_uuid>

    When we make an api get call to instances/<registry:instance_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should not have {"vif":[...,{"port_id":},...]} equal to nil

      And from the previous api call take {"vif":[...,,...]} and save it to <registry:vif> for {"network_id":} equal to "nw-demo1"
      And from <registry:vif> take {"port_id":} and save it to <registry:port_uuid>
      And from <registry:vif> take {"ipv4":{"address":}} and save it to <registry:ip>

    Then we should be able to ping on ip <registry:ip> in 60 seconds or less

    When we make an api put call to instances/<registry:instance_uuid>/stop with no options
      Then the previous api call should be successful

    When the created instance has reached the state "stopped"
    
    When we make an api put call to ports/<registry:port_uuid>/detach with no options
      Then the previous api call should be successful

    # Verify the vnic is not attached.

    When we make an api put call to instances/<registry:instance_uuid>/start with no options
      Then the previous api call should be successful

    When the created instance has reached the state "running"

    When we make an api get call to instances/<registry:instance_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should have {"vif":[...,{"port_id":},...]} equal to nil

      And from the previous api call take {"vif":[...,,...]} and save it to <registry:vif> for {"network_id":} equal to "nw-demo1"
      And from <registry:vif> take {"ipv4":{"address":}} and save it to <registry:ip>

    Then we should not be able to ping on ip <registry:ip> in 60 seconds or less

    # Attach the vnic, restart.

    # Verify that ping succeeds.
