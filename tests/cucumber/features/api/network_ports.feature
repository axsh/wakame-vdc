Feature: Network Ports API

  Scenario: Port lifecycle
    Given a new network with its uuid in registry network_uuid
    
    # Make dedicated function for getting list size...
    When we make an api get call to networks/<registry:network_uuid>/get_port with no options
      Then the previous api call should be successful
      And the previous api call root array should have 0 entries

    When we make an api put call to networks/<registry:network_uuid>/add_port with no options
      Then the previous api call should be successful
      # Check returned values
      And from the previous api call save to registry port_uuid the value for key uuid

    When we make an api get call to networks/<registry:network_uuid>/get_port with no options
      Then the previous api call should be successful
      And the previous api call root array should have 1 entries
      # Check returned values

    When we make an api put call to networks/<registry:network_uuid>/del_port with the following options
      | port_id              |
      | <registry:port_uuid> |
      Then the previous api call should be successful

    When we make an api get call to networks/<registry:network_uuid>/get_port with no options
      Then the previous api call should be successful
      And the previous api call root array should have 0 entries


  Scenario: Verify port values
    Given a new network with its uuid in registry network_uuid
    
    When we make an api put call to networks/<registry:network_uuid>/add_port with no options
      Then the previous api call should be successful
      # Check returned values
      And the previous api call should have the key network_id with <registry:network_uuid>
      And from the previous api call save to registry port_uuid the value for key uuid
      
    When we make an api get call to ports/<registry:port_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have the key uuid with <registry:port_uuid>
      And the previous api call should have the key network_id with <registry:network_uuid>


  # Verify that deleting a network remmoves the network ports.
