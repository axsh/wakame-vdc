@api_from_v12.03
Feature: Network Ports API

  Scenario: Port lifecycle
    Given a new network with its uuid in <network_uuid>
    
    # Make dedicated function for getting list size...
    When we make an api get call to networks/<network_uuid>/ports with no options
      Then the previous api call should be successful
      And the previous api call should have [{"results":[]}] with a size of 0

    # When we make an api post call to networks/<network_uuid>/ports with no options
    When we make an api post call to networks/<network_uuid>/ports with no options
      Then the previous api call should be successful
      # Check returned values
      And from the previous api call take {"uuid":} and save it to <port_uuid>

    When we make an api get call to networks/<network_uuid>/ports with no options
      Then the previous api call should be successful
      And the previous api call should have [{"results":[]}] with a size of 1
      # Check returned values

    When we make an api delete call to networks/<network_uuid>/ports/<port_uuid> with no options
      Then the previous api call should be successful

    When we make an api get call to networks/<network_uuid>/ports with no options
      Then the previous api call should be successful
      And the previous api call should have [{"results":[]}] with a size of 0


  Scenario: Verify port values
    Given a new network with its uuid in <network_uuid>
    
    # When we make an api post call to networks/<network_uuid>/ports with no options
    When we make an api post call to networks/<network_uuid>/ports with no options
      Then the previous api call should be successful
      And from the previous api call take {"uuid":} and save it to <port_uuid>
      And the previous api call should have {"network_id":} equal to <network_uuid>
      And the previous api call should have {"attachment":{}} with a size of 0
      And the previous api call should not have {} with the key "instance_nic"
      And the previous api call should not have {} with the key "instance_nic_id"
      
    When we make an api get call to networks/<network_uuid>/ports/<port_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"uuid":} equal to <port_uuid>
      And the previous api call should have {"network_id":} equal to <network_uuid>
      And the previous api call should have {"attachment":{}} with a size of 0
      And the previous api call should not have {} with the key "instance_nic"
      And the previous api call should not have {} with the key "instance_nic_id"

  # Verify that deleting a network remmoves the network ports.
